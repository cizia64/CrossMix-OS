#!/bin/sh

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [KEY_CODE]"
    echo "Example (MENU button): $0 1"
    exit 1
fi

KEY_CODE=$1

# Emplacement de l'événement clavier, changez-le si nécessaire
KEYBOARD_EVENT="/dev/input/event3"

# Vérifier si le fichier de l'événement clavier existe
if [ ! -e "$KEYBOARD_EVENT" ]; then
    echo "Le périphérique d'entrée $KEYBOARD_EVENT n'est pas disponible."
    exit 1
fi

# Débogage : Afficher la valeur de KEY_CODE
echo "KEY_CODE: $KEY_CODE"

# Utiliser evtest pour lire les événements de clavier pendant 5 secondes
timeout 5 /mnt/SDCARD/System/usr/trimui/scripts/evtest "$KEYBOARD_EVENT" | while IFS= read -r line; do
    # Rechercher le KEY_CODE dans la ligne actuelle
    if echo "$line" | grep -q "type 1 (EV_KEY), code $KEY_CODE"; then
        # extraire l'état de la touche
        state=$(echo "$line" | awk '{print $NF}')
        echo "Key $KEY_CODE state: $state"
		break
    fi
done
