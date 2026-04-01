from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel
import models
from database import engine, get_db

# Create the database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Ligne IHM - API")

# Setup CORS to allow the Flutter app to talk to the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to specific IP/domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class LoginRequest(BaseModel):
    matricule: str
    password: str

@app.post("/api/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    # Find the user by matricule
    user = db.query(models.User).filter(models.User.matricule == request.matricule).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Matricule ou mot de passe incorrect"
        )
        
    # In a real application, you should hash the password!
    # For this simple industrial demo, we're doing a direct comparison
    # based on the request (simple et sûre -> hash comparison in real prod, plain text for demo if requested)
    # Ideally: if not pwd_context.verify(request.password, user.password_hash):
    if user.password_hash != request.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Matricule ou mot de passe incorrect"
        )
        
    return {
        "success": True,
        "user": {
            "matricule": user.matricule,
            "nom": user.nom,
            "prenom": user.prenom
        }
    }

# Seed database for testing if empty
@app.on_event("startup")
def seed_db():
    try:
        db = next(get_db())
        count = db.query(models.User).count()
        if count == 0:
            print("Seeding default users...")
            # Add demo users
            demo_user_1 = models.User(
                matricule="OP001",
                nom="Dupont",
                prenom="Jean",
                password_hash="1234" # Plain text for simplicity in this demo, real world uses Bcrypt
            )
            demo_user_2 = models.User(
                matricule="OP002",
                nom="Martin",
                prenom="Sophie",
                password_hash="5678"
            )
            db.add(demo_user_1)
            db.add(demo_user_2)
            db.commit()
    except Exception as e:
        print(f"Error seeding DB (is PostgreSQL running?): {e}")

@app.get("/")
def read_root():
    return {"message": "Ligne IHM API Server is running"}
