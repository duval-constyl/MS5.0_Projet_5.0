from sqlalchemy import Column, Integer, String
from database import Base

class User(Base):
    __tablename__ = "utilisateurs"

    id = Column(Integer, primary_key=True, index=True)
    matricule = Column(String, unique=True, index=True)
    nom = Column(String)
    prenom = Column(String)
    password_hash = Column(String)
