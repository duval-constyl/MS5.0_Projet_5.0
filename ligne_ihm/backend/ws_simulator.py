import asyncio
import websockets
import json

# Simulateur WebSocket pour tester l'IHM Flutter
# Ce script simule le comportement de Node-RED

clients = set()

async def handler(websocket):
    clients.add(websocket)
    print("Nouveau client connecté (Tablette)")
    try:
        async for message in websocket:
            print(f"Message reçu de la tablette : {message}")
            try:
                data = json.loads(message)
                if data.get('type') == 'VALIDATION':
                    print(f"L'opérateur {data.get('operateur')} a validé l'OF {data.get('of')} (Tag: {data.get('tag')}) au poste {data.get('poste')}")
                    # Quand le chariot est validé, il quitte le poste
                    await send_to_all({"type": "CHANGEMENT_POSTE", "poste_source": data.get('poste')})
                
                elif data.get('type') == 'ANDON':
                    print(f"ALERTE ANDON déclenchée par {data.get('operateur')} au poste {data.get('poste')}!")
                    # Le Node-RED relaierait l'alerte à tous les postes
                    await send_to_all({"type": "ANDON", "poste": data.get('poste')})
                    
            except json.JSONDecodeError:
                print("Message invalide reçu")
    finally:
        clients.remove(websocket)
        print("Client déconnecté")

async def send_to_all(message_dict):
    if clients:
        message = json.dumps(message_dict)
        await asyncio.gather(*(client.send(message) for client in clients))

async def interactive_console():
    # Simuler l'arrivée d'un chariot depuis le terminal Server
    while True:
        await asyncio.sleep(0.5)
        # Utiliser run_in_executor pour ne pas bloquer l'Event Loop
        loop = asyncio.get_event_loop()
        cmd = await loop.run_in_executor(None, input, "Tapez '1' pour envoyer l'OF 2024-0012 au Poste 1, '2' pour simuler son départ : \n")
        
        if cmd == '1':
             payload = {
                  "type": "NOUVEAU_CHARIOT",
                  "poste": 1,
                  "tag": "RFID-12345",
                  "instructions": {
                    "of": "OF-2024-0012",
                    "variante": "Modèle Standard V2",
                    "etapes": [
                      "1. Visser la plaque arrière (4 vis)",
                      "2. Connecter le faisceau rouge au port A",
                      "3. Vérifier l'allumage de la LED de test"
                    ],
                    "temps_alloue": 15
                  }
                }
             print(">> Envoi de l'OF au poste 1...")
             await send_to_all(payload)
             
        elif cmd == '2':
             payload1 = {
                  "type": "CHANGEMENT_POSTE",
                  "poste_source": 1
             }
             print(">> Envoi de l'ordre de départ (CHANGEMENT_POSTE) au poste 1...")
             await send_to_all(payload1)


async def main():
    async with websockets.serve(handler, "0.0.0.0", 1880):
        print("Simulateur WebSocket démarré sur ws://0.0.0.0:1880/ws")
        await interactive_console()

if __name__ == "__main__":
    asyncio.run(main())
