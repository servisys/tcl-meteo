# meteo.tcl - Eggdrop !meteo <città> via OpenWeatherMap
# Configura in eggdrop.conf:
#   set meteo_api_key "TUO_API_KEY"
#   source /path/to/meteo.tcl

putlog "\[meteo.tcl\] Script caricato"

# Fallback: leggi la chiave dalla variabile d'ambiente se non impostata in conf
if {![info exists ::meteo_api_key] || $::meteo_api_key eq ""} {
    catch {set ::meteo_api_key $::env(OWM_API_KEY)}
}

proc url_encode {s} {
    set res ""
    foreach c [split $s ""] {
        if {[string is alnum -strict $c] || $c in {. _ ~ -}} {
            append res $c
        } elseif {$c eq " "} {
            append res +
        } else {
            binary scan $c c code
            append res [format "%%%02X" [expr {$code & 0xff}]]
        }
    }
    return $res
}

proc meteo_fetch {city} {
    if {![info exists ::meteo_api_key] || $::meteo_api_key eq ""} {
        return "Errore: meteo_api_key non impostata nel conf."
    }
    set city_trim [string trim $city]
    if {$city_trim eq ""} {
        return "Uso: !meteo <città>"
    }

    set city_q [url_encode $city_trim]
    set url "http://api.openweathermap.org/data/2.5/weather?q=${city_q}&appid=${::meteo_api_key}&units=metric&lang=it"

    if {[catch {set resp [exec curl -s -m 10 $url]} err]} {
        return "Impossibile contattare il servizio meteo."
    }
    if {$resp eq ""} {
        return "Risposta vuota dal servizio meteo."
    }

    # Controlla codice errore API
    if {[regexp {"cod"\s*:\s*"?(\d+)"?} $resp -> cod] && $cod ne "200"} {
        regexp {"message"\s*:\s*"([^"]+)"} $resp -> msg
        return "Errore meteo: [expr {[info exists msg] ? $msg : $cod}]"
    }

    set weather "n/a"; set temp "n/a"; set feels_like "n/a"
    set humidity "n/a"; set wind_speed "n/a"
    set cityname $city_trim; set country "??"

    regexp {"description"\s*:\s*"([^"]+)"} $resp -> weather
    regexp {"temp"\s*:\s*(-?[0-9.]+)} $resp -> temp
    regexp {"feels_like"\s*:\s*(-?[0-9.]+)} $resp -> feels_like
    regexp {"humidity"\s*:\s*([0-9]+)} $resp -> humidity
    regexp {"speed"\s*:\s*([0-9.]+)} $resp -> wind_speed
    regexp {"name"\s*:\s*"([^"]+)"} $resp -> cityname
    regexp {"country"\s*:\s*"([^"]+)"} $resp -> country

    return "Meteo ${cityname}, ${country}: ${weather} | Temp: ${temp}°C (percepiti ${feels_like}°C) | Umidità: ${humidity}% | Vento: ${wind_speed} m/s"
}

# Risponde al comando !meteo in canale
proc meteo_pub {nick uhost hand chan text} {
    set city [string trim $text]
    if {$city eq ""} {
        putquick "PRIVMSG $chan :$nick: uso: !meteo <città>"
        return
    }
    putquick "PRIVMSG $chan :[meteo_fetch $city]"
}

# Risponde al comando !meteo in privato
proc meteo_msg {nick uhost hand text} {
    set city [string trim $text]
    if {$city eq ""} {
        putquick "PRIVMSG $nick :Uso: !meteo <città>"
        return
    }
    putquick "PRIVMSG $nick :[meteo_fetch $city]"
}

# Registrazione bind - pub vuole la maschera del comando
bind pub -|- !meteo meteo_pub
bind msg -|- !meteo meteo_msg

putlog "\[meteo.tcl\] Bind !meteo registrato (pub + msg)"