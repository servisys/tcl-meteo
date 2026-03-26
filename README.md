# tcl-meteo
TCL per il meteo

## Uso (Eggdrop)
1. Ottieni una API Key gratuita da OpenWeatherMap: https://openweathermap.org/appid
2. In `eggdrop.conf` aggiungi:
   - `set meteo_api_key "tuachiave"
   - `source /percorso/assoluto/meteo.tcl`
3. Riavvia Eggdrop.
4. In canale IRC digita:
   - `!meteo Milano`

Esempio risposta: `Meteo Milano,IT: cielo sereno, temperatura 18°C (sensazione 17°C), umidità 45%, vento 3.5 m/s.`

## Uso CLI (opzionale)
1. Imposta API key anche in variabile d'ambiente (se non configurata in eggdrop.conf):
   - `export OWM_API_KEY="tuachiave"`
2. Rendi eseguibile lo script:
   - `chmod +x meteo.tcl`
3. Esegui:
   - `./meteo.tcl !meteo Milano`

Risposta di esempio: stessa formattazione sopra.
