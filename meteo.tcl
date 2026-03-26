#!/usr/bin/env tclsh
# Eggdrop: comando !meteo <città>
# Il bot legge il comando da canale IRC ed esegue request OpenWeatherMap.
# Usa: !meteo Milano
# In eggdrop.conf:
#   set meteo_api_key "TUO_API_KEY"
#   source /path/to/meteo.tcl

# Imposta in priority la variabile globale usata dal bot
if {![info exists ::meteo_api_key] || $::meteo_api_key eq ""} {
    set ::meteo_api_key [string trim [::env(OWM_API_KEY)]]
}

proc url_encode {s} {
    set res ""
    foreach c [split $s ""] {
        if {[string is alnum -strict $c] || $c eq "." || $c eq "_" || $c eq "~" || $c eq "-"} {
            append res $c
        } elseif {$c eq " "} {
            append res +
        } else {
            binary scan $c c code
            append res [format "%%%02X" $code]
        }
    }
    return $res
}

proc meteo_api_request {api_key city} {
    set city_trim [string trim $city]
    if {$city_trim eq ""} {
        return "Uso: !meteo <città>"
    }
    set city_q [url_encode $city_trim]
    set url "http://api.openweathermap.org/data/2.5/weather?q=$city_q&appid=$api_key&units=metric&lang=it"

    if {[catch {set resp [exec curl -s -m 10 $url]} err]} {
        return "Impossibile contattare il servizio meteo (timeout/rete)."
    }
    if {$resp eq ""} {
        return "Risposta vuota dal servizio meteo."
    }

    set weather "?"
    set temp "?"
    set feels_like "?"
    set humidity "?"
    set wind_speed "?"
    set cityname $city_trim
    set country "??"
    set cod 0
    set msg ""

    if {[regexp {"cod"\s*:\s*([0-9]+)} $resp -> codval]} {
        set cod $codval
    }
    if {[regexp {"message"\s*:\s*"([^"]+)"} $resp -> msgval]} {
        set msg $msgval
    }
    if {$cod != 200 && $cod != 0} {
        return "Errore meteo: $msg"
    }

    if {[regexp {"weather"\s*:\s*\[\s*\{[^\}]*"description"\s*:\s*"([^"]+)"} $resp -> weather]} {
        ;# già settato
    }
    if {[regexp {"temp"\s*:\s*([0-9.+-]+)} $resp -> temp]} {
    }
    if {[regexp {"feels_like"\s*:\s*([0-9.+-]+)} $resp -> feels_like]} {
    }
    if {[regexp {"humidity"\s*:\s*([0-9]+)} $resp -> humidity]} {
    }
    if {[regexp {"speed"\s*:\s*([0-9.+-]+)} $resp -> wind_speed]} {
    }
    if {[regexp {"name"\s*:\s*"([^"]+)"} $resp -> cityname]} {
    }
    if {[regexp {"country"\s*:\s*"([^"]+)"} $resp -> country]} {
    }

    if {$weather eq ""} {set weather "n/a"}
    if {$temp eq ""} {set temp "n/a"}
    if {$feels_like eq ""} {set feels_like "n/a"}
    if {$humidity eq ""} {set humidity "n/a"}
    if {$wind_speed eq ""} {set wind_speed "n/a"}
    if {$cityname eq ""} {set cityname $city_trim}

    return "Meteo $cityname,$country: $weather, temperatura $temp°C (sensazione $feels_like°C), umidità ${humidity}% , vento ${wind_speed} m/s."
}

proc meteo_pubm {nick uhost hand chan text} {
    if {[regexp -nocase {^!meteo(?:\s+(.*))?$} $text -> city]} {
        set city [string trim $city]
        if {$city eq ""} {
            putquick "PRIVMSG $chan :$nick, uso: !meteo <città>"
            return
        }
        if {![info exists ::meteo_api_key] || $::meteo_api_key eq ""} {
            putquick "PRIVMSG $chan :$nick, errore: meteo_api_key non impostata (eggdrop.conf o env OWM_API_KEY)."
            return
        }
        set reply [meteo_api_request $::meteo_api_key $city]
        putquick "PRIVMSG $chan :$nick, $reply"
    }
}

# Registrazione Eggdrop bind se possibile
if {[catch {bind pubm meteo meteo_pubm} err]} {
    puts {[meteo.tcl] Eggdrop bind non disponibile: $err}
} else {
    puts {[meteo.tcl] Comando !meteo registrato su eventi pubm}
}

# fallback CLI se invocato direttamente
if {[info exists argv] && [llength $argv] > 0} {
    set cmd [lindex $argv 0]
    if {$cmd ne "!meteo"} {
        puts "Comando non riconosciuto. Usa !meteo <città>."
        exit 0
    }
    set city [join [lrange $argv 1 end] " "]
    if {$city eq ""} {
        puts "Uso: !meteo <città>"
        exit 0
    }
    if {![info exists ::meteo_api_key] || $::meteo_api_key eq ""} {
        puts "Errore: meteo_api_key non impostata.";
        exit 1
    }
    puts [meteo_api_request $::meteo_api_key $city]
    exit 0
}
