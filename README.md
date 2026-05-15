# scdp

Outil en C pour envoyer des messages texte entre deux machines sur des réseaux distincts. Un seul binaire joue le rôle d'envoyeur ou de receveur.

## Compilation

```bash
cmake -B build
cmake --build build
```

Le binaire se trouve dans `build/scdp`.

## Usage

### Receveur (machine qui écoute)

```bash
./build/scdp recv 9000
```

Le programme attend une connexion TCP, affiche le message reçu sur la sortie standard, puis quitte.

### Envoyeur (machine qui initie la connexion)

```bash
./build/scdp send <host> <port> <message>
```

Exemple :

```bash
./build/scdp send 203.0.113.42 9000 "Bonjour depuis l'autre réseau"
```

Les mots du message peuvent être séparés par des espaces ; tout ce qui suit le port est concaténé en un seul message.

## IP publique

Pour afficher l'IP publique IPv4 de la machine receveuse (à communiquer à l'envoyeur) :

### macOS / Linux (bash + gum)

```bash
# Prérequis : brew install gum
./scripts/public-ip.sh
./scripts/public-ip.sh --copy          # copie directe dans le presse-papiers
./scripts/public-ip.sh -s ipify        # forcer un service
```

### Windows (PowerShell)

```powershell
.\scripts\public-ip.ps1
.\scripts\public-ip.ps1 -Copy
.\scripts\public-ip.ps1 -Service ipify
```

Aide détaillée : `Get-Help .\scripts\public-ip.ps1`

Si l'exécution de scripts est bloquée : `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

## Test local

Terminal 1 :

```bash
./build/scdp recv 9000
```

Terminal 2 :

```bash
./build/scdp send 127.0.0.1 9000 "test local"
```

## Communication entre réseaux différents

Le ping ICMP entre deux machines ne garantit pas qu'un port TCP soit accessible. Pour que `scdp` fonctionne hors du même WiFi ou de la même box :

1. Lancer `scdp recv <port>` sur la machine receveuse.
2. Si le receveur est derrière une box (NAT), configurer une **redirection de port** : port TCP externe → IP locale du receveur sur le même port.
3. Depuis l'envoyeur, utiliser l'**IP publique** ou le **hostname** du receveur, pas son adresse locale (`192.168.x.x`).
4. Autoriser le port entrant dans le pare-feu de la machine receveuse.

## Protocole

| Champ     | Taille   |
|-----------|----------|
| magic     | 4 octets (`SCDP`) |
| version   | 1 octet  |
| length    | 4 octets (network byte order) |
| payload   | `length` octets |
| ack       | 1 octet (`0x06`) renvoyé par le receveur |

Taille maximale du message : 64 Ko.

## Codes de sortie

| Code | Signification |
|------|---------------|
| 0    | Succès |
| 1    | Erreur d'utilisation |
| 2    | Erreur réseau ou protocole |
