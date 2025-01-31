 ##############################################################################
#
# Motus
# v3.358 (20/04/2020)   ©2005-2020 Menz Agitat
#
# IRC: irc.epiknet.org  #boulets / #eggdrop
#
# Mes scripts sont téléchargeables sur http://www.eggdrop.fr
#
 ##############################################################################

#
# Description
#
# Ce jeu est un mélange entre le Pendu et le MasterMind.
# Le bot choisit un mot au hasard et vous devez tenter de
# deviner lequel en faisant des propositions.
# Les propositions doivent être des mots valides (elles sont
# vérifiées grâce à l'ODS6 (Officiel du Scrabble™ version 6))
# et de même longueur que le mot à trouver.
# Lorsqu'un mot est proposé, le bot signale quelles lettres
# sont bien placées (en vert) et lesquelles sont mal placées
# (en rouge).
#
# Les options paramétrables du jeu (que vous trouverez dans
# le fichier base.cfg par défaut) vous permettent de choisir
# très précisément la façon dont le jeu interagira, le niveau
# de difficulté, et tout un tas d'autres choses.
# Il est également possible de jongler entre plusieurs profils
# de configuration additionnels afin de changer par exemple la
# difficulté du jeu, la quantité de points gagnés ou perdus, etc...
# Soyez quand même conscients que changer ces paramètres
# peut avoir un impact sur les scores et statistiques et leur
# faire perdre de leur sens. Essayez donc de faire des profils
# de configuration équilibrés (ceux fournis d'origine le sont).
#
# Pour avoir une liste des commandes disponibles, vous pouvez
# taper !aide
#
# D'autres informations sont disponibles dans le fichier lisezmoi.html
#

#
# Remerciements spéciaux : 
#		RipGirl		Pour le support moral et les idées.
#		Galdinx		Pour les idées, les coups de mains, la procédure anti-freeze,
#							le template html, le beta-testing, et j'en oublie sûrement.
#		cmwagner	Pour ses 2 procs timerexists et utimerexists (issues de son
#							script toolbox.tcl).
#		Artix			Pour l'idée d'amélioration de la procédure de désinstallation.
#		Graouuuh	Pour la routine de fusion des scores en double.
#		Merwin		Pour quelques conseils d'optimisation judicieux.
#		CrazyCat	Pour l'aide concernant les soucis de reconnaissance du chan.
#		T4z				Pour le beta-testing intensif, la découverte de nombreux bugs
#							et sa coopération pour aider à les retracer.
#		ealexp		Pour les coups de main.
#		linoux		Pour avoir proposé d'utiliser la version mobile du dictionnaire
#							en ligne, plus simple à parser et moins soumise aux changements.
#		Shina			Pour le beta-testing et pour m'avoir aidé à trouver et à
#							comprendre un bug rare et difficile à reproduire.
#

#
# LICENCE:
#		Cette création est mise à disposition selon le Contrat
#		Attribution-NonCommercial-ShareAlike 3.0 Unported disponible en ligne
#		http://creativecommons.org/licenses/by-nc-sa/3.0/ ou par courrier postal à
#		Creative Commons, 171 Second Street, Suite 300, San Francisco, California
#		94105, USA.
#		Vous pouvez également consulter la version française ici :
#		http://creativecommons.org/licenses/by-nc-sa/3.0/deed.fr
#
if {[::tcl::info::commands ::motus::unload] eq "::motus::unload"} { ::motus::unload }
if { [package vcompare [lindex [split $::version] 0] 1.6.20] == -1 } { putloglev o * "\00304\[Motus - Erreur\]\003 La version de votre Eggdrop est\00304 ${::version}\003; Motus ne fonctionnera correctement que sur les Eggdrops version 1.6.20 ou supérieure." ; return }
if { [catch { package require Tcl 8.5 }] } { putloglev o * "\00304\[Motus - Erreur\]\003 Motus nécessite que Tcl 8.5 (ou plus) soit installé pour fonctionner. Votre version actuelle de Tcl est\00304 ${::tcl_version}\003." ; return }
namespace eval ::motus {

 ###############################################################################
### Configuration
 ###############################################################################

	# Profil de configuration de référence :
	# Remarques :
	#		- vous devez IMPERATIVEMENT aller éditer ce fichier pour régler le jeu.
	# 		Il contient un paramètre indispensable sans lequel Motus ne fonctionnera
	#			pas : le nom de votre chan.
	#		- ce fichier représente la configuration de référence, par dessus laquelle
	#			seront appliqués les différents profils de configuration.
	variable main_config_file "base.cfg"

	# Profil de configuration chargé par défaut
	# Remarques :
	#		- notez que tous les paramètres présents dans ce profil de configuration
	#			remplaceront de manière prioritaire ceux de la configuration de
	#			référence (voir option ci-dessus).
	#		- si vous ne souhaitez pas charger de profil de configuration spécifique
	#			et que vous voulez vous en tenir à la configuration de référence,
	#			mettez ici aussi le nom du fichier de configuration de référence (par
	#			exemple "base.cfg").
	variable profile_file "normal.cfg"

	# emplacement des fichiers des profils de configuration
	variable config_path "scripts/motus/config/"
	
 ###############################################################################
### Fin de la configuration
 ###############################################################################



	 #############################################################################
	### Initialisation
	 #############################################################################
	# initialisation de l'environnement du Motus
	variable scriptname "Motus"
	variable version "3.358.20200420"
	variable DEBUGMODE 0
	variable status 0

	# On initialise le débogueur
	proc debug_catch_delayer {args} {
		# sans ce délai, le backtrace n'a pas le temps de se faire et la variable
		# $errorInfo ne contient que l'erreur.
		after 1 ::motus::debug_catch
	}
	proc debug_catch {args} {
		if { ![::tcl::info::exists ::errorInfo] } {
			set ::errorInfo {}
		}
		if {
			(([::tcl::info::exists ::motus::last_error])
			&& ([::tcl::string::first $::motus::last_error $::errorInfo] != -1))
			|| (([::tcl::info::exists ::errorInfo])
			&& (([::tcl::string::match *::motus::* $::errorInfo] == 0)
			|| ([::tcl::string::match *::motus::debug_catch_delayer* $::errorInfo] == 1)))
		} then {
			return
		} else {
			variable last_error $::errorInfo
			set debug_prefix "\00304\[Motus - debug\]\003\00314--\003\00315--\003->"
			putloglev o * "$debug_prefix Le script $::motus::scriptname v$::motus::version a rencontré une erreur."
			putloglev o * "$debug_prefix Merci de signaler ce problème afin que l'auteur puisse le corriger."
			putloglev o * "$debug_prefix \00312\037https://forum.eggdrop.fr/Motus-t-137.html\037\003"
			putloglev o * "$debug_prefix ou sur IRC : irc.epiknet.org #eggdrop ou #boulets"
			putloglev o * "$debug_prefix Veuillez inclure TOUTES les informations suivantes dans votre rapport d'erreur :"
			foreach line [split $::errorInfo "\n"] {
				putloglev o * "$debug_prefix\00314 $line\003"
			}
			putloglev o * "$debug_prefix Donnez aussi un maximum de détails sur le contexte dans lequel l'erreur s'est produite : cela s'est-il produit juste après avoir utilisé une commande ? que les joueurs ont-ils écrit au moment où s'est produit l'erreur ? ..."
			if { ([::tcl::info::exists ::motus::motus_chan]) && ([::tcl::info::exists ::motus::public_debug_info]) && ($::motus::public_debug_info) } {
				if { ![::tcl::string::match *c* [lindex [split [getchanmode $::motus::motus_chan]] 0]] } {
					putquick "PRIVMSG $::motus::motus_chan :\00304\[AVERTISSEMENT\]\003 Motus a rencontré un problème. Un rapport d'erreur détaillé a été envoyé en partyline de l'eggdrop et ajouté à son log, merci d'en informer un administrateur. Identification de l'erreur :\00314 [::tcl::string::range $::errorInfo 0 [::tcl::string::first \n $::errorInfo]]\003"
				} else {
					putquick "PRIVMSG $::motus::motus_chan :\[AVERTISSEMENT\] Motus a rencontré un problème. Un rapport d'erreur détaillé a été envoyé en partyline de l'eggdrop et ajouté à son log, merci d'en informer un administrateur. Identification de l'erreur : [::tcl::string::range $::errorInfo 0 [::tcl::string::first \n $::errorInfo]]"
				}
			}
			if { ([::tcl::info::procs ::motus::debug_report] ne "")
				&& ([::tcl::info::exists ::motus::auto_generate_debug_report])
				&& ([::tcl::info::exists ::motus::auto_debug_report_file])
				&& $::motus::auto_generate_debug_report
			} then {
				::motus::debug_report $::motus::auto_debug_report_file 1
			}
		}
	}
	trace add variable ::errorInfo write ::motus::debug_catch_delayer

	##### test de l'existence d'un timer, renvoi de son ID
	##### (issu de toolbox.tcl de cmwagner <cmwagner@sodre.net>)
	proc timerexists {command} {
  	foreach i [timers] {
	    if {![::tcl::string::compare $command [lindex $i 1]]} then {
      	return [lindex $i 2]
    	}
  	}
  	return
	}

	##### test de l'existence d'un utimer, renvoi de son ID
	##### (issu de toolbox.tcl de cmwagner <cmwagner@sodre.net>)
	proc utimerexists {command} {
	  foreach i [utimers] {
    	if {![::tcl::string::compare $command [lindex $i 1]]} then {
	      return [lindex $i 2]
    	}
  	}
  	return
	}

	proc unload {args} {
		putlog "Désallocation des ressources du Motus..."
		if { $::motus::status >= 1 } { 
			putqueue "PRIVMSG $::motus::motus_chan :[code warning]Rechargement du Motus, le jeu est stoppé.[code stop][code normaltext] Nous vous prions de bien vouloir nous excuser pour le dérangement occasionné. Vous pouvez relancer le jeu en tapant [code stop][code specialtext1]\002$::motus::start_cmd\002[code stop][code normaltext] si vous le souhaitez.[code stop]"
		}
		foreach binding [lsearch -inline -all -regexp [binds *[set ns [::tcl::string::range [namespace current] 2 end]]*] " \{?(::)?$ns"] {
			unbind [lindex $binding 0] [lindex $binding 1] [lindex $binding 2] [lindex $binding 4]
		}
		foreach running_timer [timers] {
			if { [::tcl::string::match "*[namespace current]::*" [lindex $running_timer 1]] } { killtimer [lindex $running_timer 2] }
		}
		foreach running_utimer [utimers] {
			if { [::tcl::string::match "*[namespace current]::*" [lindex $running_utimer 1]] } { killutimer [lindex $running_utimer 2] }
		}
		# arrêt du débogueur
		trace remove variable ::errorInfo write ::motus::debug_catch_delayer
		namespace delete ::motus
	}

	##### traitement des données de configuration
	proc post_config {} {
		# Vérification de la validité du chan défini
		if {(![validchan $::motus::motus_chan]) && ([lsearch [::tcl::string::tolower [channels]] [::tcl::string::tolower $::motus::motus_chan]] == -1) && ($::motus::motus_chan ne "#votrechan")} {
			putloglev o * "\00304\002\[Motus - info\]\002\003 Création d'un enregistrement pour le chan \00307\002$::motus::motus_chan\002\003."
			channel add $::motus::motus_chan
		}
		if { $::motus::motus_chan eq "#votrechan" } { putloglev o * "\00304\037Erreur\037\003 : Vous n'avez pas configuré correctement le fichier \002$::motus::main_config_file\002. Il est nécessaire de paramétrer le jeu pour qu'il sache sur quel chan il doit s'activer." ; return 0 }
		if { ![file exists $::motus::wordlist_file] } { putloglev o * "\00304\037Erreur\037\003 : La base de données de mots n'a pas été trouvée à cet emplacement : \002$::motus::wordlist_file\002." ; return 0 }
		if { ![file exists $::motus::dictionary_file] } { putloglev o * "\00304\037Erreur\037\003 : Le dictionnaire de vérification n'a pas été trouvé à cet emplacement : \002$::motus::dictionary_file\002." ; return 0 }
		set ::motus::html_filename [regsub -all {[^[:alnum:]\.]} $::motus::html_filename "_"]
		set ::motus::css_filename [regsub -all {[^[:alnum:]\.]} $::motus::css_filename "_"]
		if { ($::motus::html_export) && (![file exists "[set ::motus::html_template_path]index.html"]) } { putloglev o * "\00304\037Erreur\037\003 : Le template pour l'exportation HTML n'a pas été trouvé à cet emplacement : \002[set ::motus::html_template_path]index.html\002." ; return 0 }
		if { ($::motus::html_export) && (![file exists "[set ::motus::html_template_path]style.css"]) } { putloglev o * "\00304\037Erreur\037\003 : La feuille de style pour l'exportation HTML n'a pas été trouvée à cet emplacement : \002[set ::motus::html_template_path]style.css\002." ; return 0 }
		# Added by CC : check for expformat.tcl in template path
		if { [file exists "[set motus::html_template_path]expformat.tcl"] } { source [set motus::html_template_path]expformat.tcl }
		# End addition by CC
		if { [::tcl::string::match -nocase "*$::motus::clearscores_day*" "lundi mardi mercredi jeudi vendredi samedi dimanche"] == 0 } { putloglev o * "\00304\037Erreur\037 :\003 Le jour défini dans les paramètres pour la remise à 0 des scores n'est pas valide : \002\00304$::motus::clearscores_day\003\002. Le jour doit être \002lundi\002, \002mardi\002, \002mercredi\002, \002jeudi\002, \002vendredi\002, \002samedi\002 ou \002dimanche\002" ; return 0 }
		if { $::motus::advertise } { variable advertise_targets [split $::motus::advertise_targets] }
		set ::motus::clearscores_time [split $::motus::clearscores_time "h"] 
		bind pubm -|- "$::motus::motus_chan %!motus *%" ::motus::game_init
		bind pubm $::motus::start_flags "$::motus::motus_chan %$::motus::start_cmd%" ::motus::game_init
		bind pubm $::motus::help_flags "$::motus::motus_chan %$::motus::help_cmd%" ::motus::help
		bind pubm $::motus::scores_flags "$::motus::motus_chan %$::motus::scores_cmd%" ::motus::display_scores
		bind pubm $::motus::score_flags "$::motus::motus_chan %$::motus::score_cmd%" ::motus::ask_score
		bind pubm $::motus::score_flags "$::motus::motus_chan %$::motus::score_cmd *%" ::motus::ask_score
		bind pubm $::motus::place_flags "$::motus::motus_chan %$::motus::place_cmd%" ::motus::ask_place
		bind pubm $::motus::place_flags "$::motus::motus_chan %$::motus::place_cmd *%" ::motus::ask_place
		bind pubm $::motus::stat_flags "$::motus::motus_chan %$::motus::stat_cmd%" ::motus::ask_stat
		bind pubm $::motus::stat_flags "$::motus::motus_chan %$::motus::stat_cmd *%" ::motus::ask_stat
		bind pubm $::motus::records_flags "$::motus::motus_chan %$::motus::records_cmd%" ::motus::ask_records
		bind pubm $::motus::clearscores_flags "$::motus::motus_chan %$::motus::clearscores_cmd%" ::motus::clear_scores
		bind pubm $::motus::resetstats_flags "$::motus::motus_chan %$::motus::resetstats_cmd%" ::motus::reset_stats
		bind pubm $::motus::findplayers_flags "$::motus::motus_chan %$::motus::findplayers_cmd%" ::motus::find_players
		bind pubm $::motus::findplayers_flags "$::motus::motus_chan %$::motus::findplayers_cmd *%" ::motus::find_players
		bind pubm $::motus::playersfusion_flags "$::motus::motus_chan %$::motus::playersfusion_cmd%" ::motus::ask_fusion
		bind pubm $::motus::playersfusion_flags "$::motus::motus_chan %$::motus::playersfusion_cmd *%" ::motus::ask_fusion
		bind pubm $::motus::playerrename_flags "$::motus::motus_chan %$::motus::playerrename_cmd%" ::motus::ask_rename
		bind pubm $::motus::playerrename_flags "$::motus::motus_chan %$::motus::playerrename_cmd *%" ::motus::ask_rename
		bind pubm $::motus::htmlupdate_flags "$::motus::motus_chan %$::motus::htmlupdate_cmd%" ::motus::manual_html_export
		bind pubm $::motus::config_flags "$::motus::motus_chan %$::motus::config_cmd%" ::motus::config_change
		bind pubm $::motus::config_flags "$::motus::motus_chan %$::motus::config_cmd *%" ::motus::config_change
		variable pending_profile_change 0
		variable special_queue_running 0
		if { $::motus::players_can_change_profile } {
			bind pubm $::motus::selectable_profiles_list_flags "$::motus::motus_chan %$::motus::selectable_profiles_list_cmd%" ::motus::list_users_selectable_profiles
			bind pubm $::motus::profile_change_flags "$::motus::motus_chan %$::motus::profile_change_cmd%" ::motus::ask_for_profile_change
			bind pubm $::motus::profile_change_flags "$::motus::motus_chan %$::motus::profile_change_cmd *%" ::motus::ask_for_profile_change
			bind sign -|- "$::motus::motus_chan *" ::motus::user_has_left
			bind part -|- "$::motus::motus_chan *" ::motus::user_has_left
			bind time - "* * * * *" ::motus::check_for_expired_active_players
		}
		bind evnt - prerehash ::motus::unload
		bind time - "[lindex $::motus::clearscores_time 1] [lindex $::motus::clearscores_time 0] * * *" ::motus::stats_week_change
		if { $::motus::clearscoresweekly } { bind time - "[lindex $::motus::clearscores_time 1] [lindex $::motus::clearscores_time 0] * * *" ::motus::clear_scores_weekly }
		if { $::motus::daily_backup } { bind time - "00 00 * * *" ::motus::backup_files }
		if { $::motus::html_export } {
			if {[set htmltimer [motus::timerexists {::motus::html_export "auto"}]] ne ""} { killtimer $htmltimer }
			timer $::motus::html_export_interval {::motus::html_export "auto"}
		}
		if { $::motus::min_word_length > $::motus::max_word_length } { variable min_word_length $::motus::max_word_length }
		if { $::motus::max_word_length < 4 } {
			variable max_word_length 4
		} elseif { $::motus::max_word_length > 15 } {
				variable max_word_length 15
		}
		if { $::motus::min_word_length < 4 } {
			variable min_word_length 4
		} elseif { $::motus::min_word_length > 15 } {
			variable min_word_length 15
		}
		if { ($::motus::auto_hint_mode != 1) && ($::motus::auto_hint_mode != 2) } { variable auto_hint_mode 2 }
		# On s'assure que le nombre d'indices placés dès le départ n'est pas supérieur à (longueur du mot - 1)
		for { set counter $::motus::min_word_length } { $counter <= $::motus::max_word_length } { incr counter } {
			if { $::motus::placed_hints($counter) > [expr $counter - 1] } { set ::motus::placed_hints($counter) [expr $counter - 1] }
		}
		set subcounter 1
		# Construction de l'array qui servira à choisir un mot en fonction de sa longueur
		for { set counter $::motus::min_word_length } { $counter <= $::motus::max_word_length } { incr counter } {
			regsub {%} $::motus::wordlength_weight($counter) "" ::motus::computed_wordlength_weight($counter)
			lappend total_wordlength_weight_tmp "+$::motus::computed_wordlength_weight($counter)"
			set increment $::motus::computed_wordlength_weight($counter)
			set ::motus::computed_wordlength_weight($counter) "$subcounter,[expr $::motus::computed_wordlength_weight($counter) + $subcounter - 1]"
			incr subcounter $increment
		}
		variable total_wordlength_weight [expr $total_wordlength_weight_tmp]
		if { $::motus::define_words } {
			package require http
			if { [catch { package require tls 1.5 }] } {
				putloglev o * "\00304\[Motus - erreur\]\003 Motus nécessite le package tls 1.5 (ou plus) pour fonctionner. L'affichage de la définition des mots a été désactivé."
				set ::motus::define_words 0
			} else {
				variable useragent "Mozilla/5.0 (Windows NT 5.1; rv:17.0) Gecko/20100101 Firefox/17.0"
				variable dictionary_parse_URL "https://www.notrefamille.com/dictionnaire/definition/\$mot"
				variable dictionary_domain_URL "https://www.notrefamille.com"
			}
		}
		if { $::motus::achievements_enabled } {
			# on stocke le nombre de hauts faits différents dans une variable
			variable num_achievements 60
			# on stocke le nombre maximum de points de hauts faits dans une variable
			variable max_achievements_points 200
		}
		variable announce_freq [regsub % $::motus::announce_freq ""]
		# Création des 2 arrays contenant le nombre de mots de chaque longueur
		array set ::motus::wordlist_length_offsets {4 1661 5 4513 6 8458 7 12399 8 15289 9 16217 10 14701 11 11696 12 8673 13 5947 14 3728 15 2202}
		array set ::motus::dico_length_offsets {4 2509 5 7645 6 17318 7 31070 8 46329 9 57467 10 60487 11 55436 12 44468 13 31491 14 19892 15 11462}
		return 1
	}
	variable active_players_hostlist {}
	variable vote_is_pending 0
	variable placed_hints ;	array set placed_hints {}
	variable wordlength_weight ; array set wordlength_weight {}
	variable computed_wordlength_weight ; array set computed_wordlength_weight {}
	# Lecture du/des fichier(s) de configuration
	variable main_config_name [lindex [split $main_config_file "."] 0]
	variable main_config_file_full "[set ::motus::config_path][set ::motus::main_config_file]"
	if { ![file exists $::motus::main_config_file_full] } { putloglev o * "\00304\002\[Motus - erreur\]\002\003 Le fichier de configuration de référence n'a pas été trouvé à cet emplacement : \002$::motus::main_config_file_full\002.\003" ; return }
	eval [list source $::motus::main_config_file_full]
	if { $::motus::profile_file ne $::motus::main_config_file } {
		variable profile_name	[lindex [split $profile_file "."] 0]
		variable default_profile_name $profile_name
		variable profile_file_full "[set ::motus::config_path][set ::motus::profile_file]"
		if { ![file exists $::motus::profile_file_full] } { putloglev o * "\00304\002\[Motus - erreur\]\002\003 Le profil de configuration n'a pas été trouvé à cet emplacement : \002$::motus::profile_file_full\002.\003" ; return }
		set ::motus::profile_description {}
		eval [list source $::motus::profile_file_full]
	}
	variable ::motus_script_file [::tcl::info::script]
	if { ![motus::post_config] } { return }
	# si le flag motus n'existe pas encore sur le chan, c'est qu'il s'agit du 1er lancement du script
	# alors on l'active par défaut.
	if { [lsearch -regexp [channel info $::motus::motus_chan] {^(\+|\-)motus$}] == -1 } {
		setudef flag motus
		channel set $::motus::motus_chan +motus 
	} else {
		setudef flag motus
	}
	# Si le fichier variables.txt existe, on le renomme en variables.txt.old (fichier obsolète)
	if {[file exists "scripts/motus/variables.txt"]} { file rename -force -- "scripts/motus/variables.txt" "scripts/motus/variables.txt.old" }
}

##### Affiche la liste des commandes disponibles selon les autorisations
proc ::motus::help {nick host hand chan args} {
	if {![channel get $::motus::motus_chan motus]} { return }
	regexp {(.*) (.*)} [split [chattr $hand $::motus::motus_chan] "|"] dummy user_global_flags user_local_flags
	if {$hand eq "*"} {
		set user_local_flags "-"
		set user_global_flags "-"
	}
	if {$::motus::help_mode} { set help_mode2 "PRIVMSG" } { set help_mode2 "NOTICE" }
	if { $::motus::players_can_change_profile } {
		set cmd_prefix_list {start stop scores score place stat records repeat next hint clearscores resetstats findplayers playersfusion playerrename htmlupdate on-off reload config profile_change profile_voting selectable_profiles_list version report}
	} else {
		set cmd_prefix_list {start stop scores score place stat records repeat next hint clearscores resetstats findplayers playersfusion playerrename htmlupdate on-off reload config version report}
	}
	foreach command [split $cmd_prefix_list " "] {
		if {($command eq "on-off") || ($command eq "reload") || ($command eq "report")} {
			set flags $::motus::admin_flags
		} elseif { $command eq "version" } {
			set flags $::motus::start_flags
		} else {
			set flags [set ::motus::[subst $command]_flags]
		}
		regexp {(.*)\|(.*)} $flags dummy cmd_global_flags cmd_local_flags
		if { ([regexp "\[$cmd_global_flags\]" "-$user_global_flags"]) || ([regexp "\[$cmd_local_flags\]" "-$user_local_flags"]) } { set cmd_allowed 1 } { set cmd_allowed 0 }
		if {$cmd_allowed} {
			if {![::tcl::info::exists help_list]} {
				lappend help_list "\037Commandes du Motus\037 :"
			} elseif { $help_list ne "" } {
				lappend help_list " [code 07]|[code stop] "
			}
			switch -- $command {
				"start" { lappend help_list "\002$::motus::start_cmd\002 : Lance une partie." }
				"stop" { lappend help_list "\002$::motus::stop_cmd\002 : Stoppe le jeu en cours." }
				"scores" { lappend help_list "\002$::motus::scores_cmd\002 : Affiche les 10 meilleurs scores." }
				"score" { lappend help_list "\002$::motus::score_cmd [code 14]\002\[\002[code stop]nick[code 14]\002\][code stop] : Affiche le score d'un joueur." }
				"place" { lappend help_list "\002$::motus::place_cmd [code 14]\002\[\002[code stop]nick[code 14]\002\][code stop] : Affiche la place d'un joueur dans le classement." }
				"stat" { lappend help_list "\002$::motus::stat_cmd [code 14]\002\[\002[code stop]nick[code 14]\002\][code stop] : Affiche des statistiques sur un joueur." }
				"records" { lappend help_list "\002$::motus::records_cmd\002\ : Affiche les records du Motus." }
				"repeat" { lappend help_list "\002$::motus::repeat_cmd\002 : Affiche l'état du mot en cours." }
				"next" { lappend help_list "\002$::motus::next_cmd\002 : Passe au mot suivant." }
				"hint" { lappend help_list "\002$::motus::hint_cmd\002 : Affiche un indice supplémentaire." }
				"clearscores" { lappend help_list "\002$::motus::clearscores_cmd\002 : Remet les scores à zéro." }
				"resetstats" { lappend help_list "\002$::motus::resetstats_cmd\002 : Remet les statistiques à zéro." }
				"findplayers" { lappend help_list "\002$::motus::findplayers_cmd\002 [code 14]<\002[code stop]masque_de_recherche[code 14]\002>[code stop] : Affiche une liste des joueurs correspondant au masque de recherche dans les statistiques du jeu (jokers acceptés)." }
				"playersfusion" { lappend help_list "\002$::motus::playersfusion_cmd\002 [code 14]<\002[code stop]nick1[code 14]\002> <\002[code stop]nick2[code 14]\002> \[\[\002[code stop]nick3[code 14]\002\] \[[code stop]...[code 14]\]\][code stop] : Fusionne les scores et les statistiques de \002nick1\002, \002nick2\002, etc... dans \002nick1\002." }
				"playerrename" { lappend help_list "\002$::motus::playerrename_cmd\002 [code 14]<\002[code stop]ancien_nick[code 14]\002> <\002[code stop]nouveau_nick[code 14]\002>[code stop] : Renomme un joueur dans les scores / statistiques personnelles." }
				"htmlupdate" { lappend help_list "\002$::motus::htmlupdate_cmd\002 : Force une mise à jour de la page HTML affichant les statistiques." }
				"on-off" { lappend help_list "\002!motus [code 14]\002<\002[code stop]on[code 14]\002\|\002[code stop]off[code 14]\002>[code stop] : Active/désactive le jeu sur le chan $::motus::motus_chan." }
				"reload" { lappend help_list "\002!motus reload\002 : Désinstalle/réinstalle le script afin de prendre en compte d'éventuelles modifications du script ou de la configuration (équivaut à un restart de l'eggdrop qui ne s'appliquerait qu'au script du Motus)." }
				"config" { lappend help_list "\002$::motus::config_cmd [code 14]\002<\002[code stop]fichier de configuration[code 14]\002>[code stop] : Applique un autre fichier de configuration." }
				"profile_change" { lappend help_list "\002$::motus::profile_change_cmd [code 14]\002<\002[code stop]profil de configuration[code 14]\002>[code stop] : Permet à un joueur actif de demander un changement de profil de configuration." }
				"profile_voting" { lappend help_list "\002$::motus::profile_voting_cmd [code 14]\002<\002[code stop]pour[code 14]\002/\002[code stop]contre[code 14]\002>[code stop] : Permet à un joueur actif de voter pour ou contre un changement de profil de configuration." }
				"selectable_profiles_list" { lappend help_list "\002$::motus::selectable_profiles_list_cmd\002 : Affiche la liste des profils de configuration disponibles à la sélection par les joueurs. Affiche aussi le profil actuellement utilisé." }
				"version" { lappend help_list "\002!motus version\002 : Affiche la version du Motus." }
				"report" { lappend help_list "\002!motus report\002 : Génère un rapport de déboguage et l'enregistre dans motus_report.txt" }
			}
		}
	}
	foreach line [::motus::split_line [join $help_list] $::motus::max_line_length] {
		lappend ::motus::special_queue "$help_mode2 $nick :$line"
	}
	lappend ::motus::special_queue [list "-END-" $chan]
	if { !$::motus::special_queue_running } {
		::motus::process_special_queue
	}
}

##### Traitement de la file d'attente parallèle pour l'affichage de l'aide
##### Cette file d'attente séparée permet de ne pas engorger la file d'attente
##### puthelp en y envoyant beaucoup de lignes d'un coup.
proc ::motus::process_special_queue {} {
	set ::motus::special_queue_running 1
	if { [lindex [set queue_line [lindex $::motus::special_queue 0]] 0] ne "-END-" } {
		puthelp $queue_line
		utimer 4 ::motus::process_special_queue
	} else {
		set ::motus::special_queue_running 0
	}
	set ::motus::special_queue [lreplace $::motus::special_queue 0 0]
	return
}

##### Activation / désactivation / rechargement du Motus / génération d'un rapport de déboguage
proc ::motus::admin_commands {nick host hand chan arg} {
	set arg [motus::strip_codes_and_spaces $arg]
	if {$arg eq "on"} {
		if { [channel get $::motus::motus_chan motus] == 1 } { 
			set livestate "déjà activé"
		} else {
			set livestate "maintenant activé"
			channel set $::motus::motus_chan +motus
		}
		putserv "PRIVMSG $::motus::motus_chan :[code normaltext]Le Motus est $livestate sur le chan $::motus::motus_chan. [code stop][code 07]|[code stop][code normaltext] Pour voir une liste des commandes disponibles, tape  [code stop][code specialtext1]\002$::motus::help_cmd\002[code stop]  [code 07]|[code stop][code normaltext] Pour lancer une partie, tape  [code stop][code specialtext1]\002$::motus::start_cmd\002[code stop]"
	} elseif {$arg eq "off"} {
		if { [channel get $::motus::motus_chan motus] == 0 } { 
			set livestate "déjà désactivé"
		} else {
			set livestate "maintenant désactivé"
			channel set $::motus::motus_chan -motus
			::motus::silent_stop 0 -
			variable pending_profile_change 0
			if { ($::motus::profile_name ne $::motus::default_profile_name) && ($::motus::restore_default_profile_at_game_end) } {
				::motus::reapply_default_profile 1
			}
		}
		putserv "PRIVMSG $::motus::motus_chan :[code normaltext]Le Motus est $livestate sur le chan $::motus::motus_chan.[code stop]"
	} elseif {$arg eq "report"} {
		::motus::debug_report "motus_report.txt" 0
	} elseif {$arg eq "reload"} {
		# procédure de rechargement du motus (équivaut à un rehash sur motus.tcl seulement)
		::motus::unload
		uplevel #0 [list source $::motus_script_file]
		putserv "PRIVMSG $::motus::motus_chan :[code normaltext]Nouvelle configuration appliquée.[code stop]"
	} else {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 :[code stop] [code normaltext]paramètre inconnu. Tape  [code stop][code specialtext1]\002!motus on\002[code stop][code normaltext]  pour activer le motus sur $::motus::motus_chan,  [code stop][code specialtext1]\002!motus off\002[code stop][code normaltext]  pour le désactiver,  [code stop][code specialtext1]\002!motus reload\002[code stop][code normaltext]  pour désinstaller/réinstaller le script afin de prendre en compte d'éventuelles modifications du script ou de la configuration,  [code stop][code specialtext1]\002!motus report\002[code stop][code normaltext]  pour générer un rapport de déboguage, ou  [code stop][code specialtext1]\002!motus version\002[code stop][code normaltext]  pour afficher la version du jeu.[code stop]"
	}
	return
}

##### Changement de configuration au moyen de la commande !config
proc ::motus::config_change {nick host hand chan arg} {
	if {![channel get $::motus::motus_chan motus]} { return }
	set arg [join [lindex [split $arg] 1]]
	if {$arg eq ""} {
		puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Configuration de référence : [code stop][code specialtext1]\002\002[set ::motus::main_config_name][code stop][code normaltext]. Profil de configuration actuellement utilisé : [if { $::motus::profile_name eq $::motus::main_config_name } { set dummy "aucun" } { set dummy "[code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext]" }].[code stop]"
		return
	}
	set temp_profile_file "[set arg].cfg"
	set temp_profile_file_full "[set ::motus::config_path][set temp_profile_file]"
	if {![file exists $temp_profile_file_full]} {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 :[code stop] [code normaltext]Ce profil de configuration n'existe pas : [code stop][code specialtext1]\002\002[set temp_profile_file_full][code stop][code normaltext].[code stop]"
	} else {
		# énumération et suppression des binds
		foreach binding [lsearch -inline -all -regexp [binds *[set ns [::tcl::string::range [namespace current] 2 end]]*] " (::)?$ns"] {
			unbind [lindex $binding 0] [lindex $binding 1] [lindex $binding 2] [lindex $binding 4]
		}
		# arrêt du timer qui contrôle la mise à jour automatique de la page de stats HTML
		if {[set htmltimer [motus::timerexists {::motus::html_export "auto"}]] ne ""} { killtimer $htmltimer }
		# arrêt d'un éventuel vote en cours pour un changement de profil (!change)
		if {[set votetimer [motus::utimerexists {::motus::vote_has_ended}]] ne ""} { killutimer $votetimer }
		set ::motus::vote_is_pending 0
		set ::motus::pending_profile_change 0
		# on importe les arrays car sinon les "set" du fichier config vont créer des variables locales
		variable wordlength_weight ; variable computed_wordlength_weight ; variable placed_hints
		eval [list source $::motus::main_config_file_full]
		variable profile_file $temp_profile_file
		variable profile_file_full $temp_profile_file_full
		variable profile_name $arg
		set ::motus::profile_description {}
		eval [list source $::motus::profile_file_full]
		if { ![motus::post_config] } { return }
		if { $::motus::status >= 1 } { 
			::motus::silent_stop 1 -
			variable pending_profile_change 0
			putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Profil de configuration [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext] appliqué, [code stop][code warning]le jeu est stoppé[code stop][code normaltext]. Nous vous prions de bien vouloir nous excuser pour le dérangement occasionné. Vous pouvez relancer le jeu en tapant  [code stop][code specialtext1]\002$::motus::start_cmd\002[code stop][code normaltext]  si vous le souhaitez.[code stop]"
		} else {
			putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Nouveau profil de configuration appliqué : [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop]"
		}
	}
}

##### Un joueur demande à changer de profil de configuration
proc ::motus::ask_for_profile_change {nick host hand chan arg} {
	set arg [join [lindex [split $arg] 1]]
	if { ![channel get $::motus::motus_chan motus] } {
		return
	} elseif { [lsearch -exact -index 0 $::motus::active_players_hostlist $host] == -1 } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Accès refusé\037 : [code stop][code normaltext]\002\002[set nick], tu dois participer au jeu pour avoir accès à cette commande.[code stop]"
		return
	} elseif { $arg eq "" } {
		puthelp "PRIVMSG $::motus::motus_chan :\037Syntaxe\037 : \002$::motus::profile_change_cmd [code 14]\002<\002[code stop]profil de configuration[code 14]\002>[code stop] : Permet de demander un changement de profil de configuration. Pour voir la liste des profils disponibles, tape \002$::motus::selectable_profiles_list_cmd\002."
		return
	} elseif { $::motus::vote_is_pending == 2 } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Accès refusé\037 : [code stop][code normaltext]Vous ne pouvez pas demander à changer le profil de configuration plus d'une fois toutes les [code stop][code specialtext1]\002\002[set ::motus::change_lock_time]mn[code stop][code normaltext]. Temps restant : [code stop][code specialtext1]\002\002[lindex [lsearch -inline [timers] "*set ::motus::vote_is_pending *"] 0]mn[code stop][code normaltext].[code stop]"
		return
	} elseif { $::motus::vote_is_pending == 1 } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Accès refusé\037 : [code stop][code normaltext]Un vote est déjà en cours pour le profil de configuration [code stop][code specialtext1]\002\002[set ::motus::current_profile_vote][code stop][code normaltext].[code stop]"
		return
	} elseif { [lsearch -exact $::motus::profiles_selectable_by_users $arg] == -1 } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code stop][code normaltext]Le profil de configuration [code stop][code specialtext1]\002\002[set arg][code stop][code normaltext] n'est pas disponible. Voici quels sont les profils disponibles : [code stop][code specialtext1]\002\002[set ::motus::profiles_selectable_by_users][code stop]"
		return
	} elseif { $::motus::profile_name eq $arg } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code stop][code normaltext]Le profil de configuration [code stop][code specialtext1]\002\002[set arg][code stop][code normaltext] est celui que nous utilisons actuellement.[code stop]"
		return
	} else {
		set ::motus::vote_is_pending 1
		set ::motus::current_profile_vote $arg
		# on considère que celui qui a lancé le vote a voté pour
		lappend ::motus::has_voted [list $host 1 0]
		bind pubm $::motus::profile_voting_flags "$::motus::motus_chan %$::motus::profile_voting_cmd *%" ::motus::vote_for_profile_change
		puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Un changement de profil de configuration a été demandé par [code stop][code specialtext1]\002\002[set nick][code stop][code normaltext]. Profil actuel : [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext]. Profil demandé : [code stop][code specialtext1]\002\002[set ::motus::current_profile_vote][code stop][code normaltext]. Les joueurs participants peuvent voter pour ou contre en tapant  [code stop][code specialtext1]\002$::motus::profile_voting_cmd pour\002[code stop][code normaltext]  ou  [code stop][code specialtext1]\002$::motus::profile_voting_cmd contre\002[code stop][code normaltext] . Le vote dure [code stop][code specialtext1]\002\002[set ::motus::vote_time][code stop][code normaltext] secondes, après quoi le changement de profil sera accepté en cas de majorité absolue ou si personne n'a voté contre.[code stop]"
		utimer $::motus::vote_time ::motus::vote_has_ended
	}
}

##### Un joueur vote pour ou contre un changement de profil de configuration
proc ::motus::vote_for_profile_change {nick host hand chan arg} {
	if { (![channel get $::motus::motus_chan motus]) || (([set vote [::tcl::string::tolower [motus::strip_codes_and_spaces [join [lindex [split $arg] 1]]]]] ne "pour") && ($vote ne "contre")) } {
		return
	} elseif { [lsearch -exact -index 0 $::motus::active_players_hostlist $host] == -1 } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Accès refusé\037 : [code stop][code normaltext]\002\002[set nick], tu dois participer au jeu pour avoir accès à cette commande.[code stop]"
		return
	} elseif { [lsearch -exact -index 0 $::motus::has_voted $host] != -1 } {
		puthelp "NOTICE $nick :Votre vote a déjà été pris en compte."
		return
	} elseif { $vote eq "pour" } {
		lappend ::motus::has_voted [list $host 1 0]
	} else {
		lappend ::motus::has_voted [list $host 0 1]
	}
	puthelp "NOTICE $nick :Votre vote a été pris en compte."
}

##### Un vote en vue d'accepter ou refuser un changement de profil de configuration vient de se terminer
proc ::motus::vote_has_ended {} {
	set ::motus::vote_is_pending 2
	unbind pubm $::motus::profile_voting_flags "$::motus::motus_chan %$::motus::profile_voting_cmd *%" ::motus::vote_for_profile_change
	if { ![channel get $::motus::motus_chan motus] } {
		::motus::cleanup
		return
	}
	set total_votes_for 0
	set total_votes_against 0
	# on compte les votes
	foreach element $::motus::has_voted {
		lassign $element {} vote_for vote_against
		incr total_votes_for $vote_for
		incr total_votes_against $vote_against
	}
	# si la majorité absolue n'a pas voté pour, on abandonne
	if { $total_votes_for <= [expr ($total_votes_for + $total_votes_against) / 2] } {
		puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Le vote est maintenant terminé. Résultat : [code stop][code specialtext1]\002\002[set total_votes_for][code stop][code normaltext] pour et [code stop][code specialtext1]\002\002[set total_votes_against][code stop][code normaltext] contre. Le profil [code stop][code specialtext1]\002\002[set ::motus::current_profile_vote][code stop][code normaltext] n'a pas été accepté à la majorité absolue, nous conservons donc le profil [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext].[code stop]"
		timer $::motus::change_lock_time {set ::motus::vote_is_pending 0}
		unset ::motus::current_profile_vote
		set ::motus::has_voted ""
		return
	# si la majorité absolue a voté pour, le changement de profil de configuration est validé
	} else {
		if {[set timebetweenturns [motus::utimerexists {::motus::motsuivant}]] ne ""} { killutimer $timebetweenturns }
		# si aucune partie n'est en cours ou si nous sommes entre 2 rounds, on applique immédiatement le nouveau profil de configuration
		if { (!$::motus::status) || ($::motus::status == 2) } {
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Le vote est maintenant terminé. Résultat : [code stop][code specialtext1]\002\002[set total_votes_for][code stop][code normaltext] pour et [code stop][code specialtext1]\002\002[set total_votes_against][code stop][code normaltext] contre. Le profil [code stop][code specialtext1]\002\002[set ::motus::current_profile_vote][code stop][code normaltext] a été accepté.[code stop]"
			::motus::apply_player_voted_profile
		# si un round de motus est en cours, on attendra qu'il se termine avant d'appliquer le nouveau profil de configuration
		} else {
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Le vote est maintenant terminé. Résultat : [code stop][code specialtext1]\002\002[set total_votes_for][code stop][code normaltext] pour et [code stop][code specialtext1]\002\002[set total_votes_against][code stop][code normaltext] contre. Le profil [code stop][code specialtext1]\002\002[set ::motus::current_profile_vote][code stop][code normaltext] sera appliqué à la fin du round en cours.[code stop]"
			set ::motus::pending_profile_change 1
		}
	}
}

##### Applique un nouveau profil de configuration après qu'il ait été voté à l'unanimité par les joueurs
proc ::motus::apply_player_voted_profile {} {
	set ::motus::pending_profile_change 0
	if { ![channel get $::motus::motus_chan motus] } { return }
	unset ::motus::has_voted
	timer $::motus::change_lock_time {set ::motus::vote_is_pending 0}
	# énumération et suppression des binds
	foreach binding [lsearch -inline -all -regexp [binds *[set ns [::tcl::string::range [namespace current] 2 end]]*] " (::)?$ns"] {
		unbind [lindex $binding 0] [lindex $binding 1] [lindex $binding 2] [lindex $binding 4]
	}
	# arrêt du timer qui contrôle la mise à jour automatique de la page de stats HTML
	if {[set htmltimer [motus::timerexists {::motus::html_export "auto"}]] ne ""} { killtimer $htmltimer }
	# on importe les arrays car sinon les "set" du fichier config vont créer des variables locales
	variable wordlength_weight ; variable computed_wordlength_weight ; variable placed_hints
	eval [list source $::motus::main_config_file_full]
	set ::motus::profile_file "[set ::motus::current_profile_vote].cfg"
	set ::motus::profile_file_full "[set ::motus::config_path][set ::motus::profile_file]"
	set ::motus::profile_name $::motus::current_profile_vote
	if { $::motus::profile_file ne $::motus::main_config_file } {
		set ::motus::profile_description {}
		eval [list source $::motus::profile_file_full]
	}
	if { ![motus::post_config] } { return }
	if { $::motus::status >= 1 } { 
		::motus::silent_stop 1 -
		putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Profil de configuration [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext] appliqué, le jeu redémarre...[code stop]"
		if { ($::motus::show_profile_description) && ($::motus::profile_description ne "") } { ::motus::show_current_profile_description }
		unset ::motus::current_profile_vote
		::motus::game_init $::botnick - - $::motus::motus_chan ""
	} else {
		puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Nouveau profil de configuration appliqué : [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop]"
		if { ($::motus::show_profile_description) && ($::motus::profile_description ne "") } { ::motus::show_current_profile_description }
		unset ::motus::current_profile_vote
	}
}

##### Réapplique le profil de configuration par défaut si un autre a été
##### chargé et que la partie se termine.
proc ::motus::reapply_default_profile {issilent} {
	# énumération et suppression des binds
	foreach binding [lsearch -inline -all -regexp [binds *[set ns [::tcl::string::range [namespace current] 2 end]]*] " (::)?$ns"] {
		unbind [lindex $binding 0] [lindex $binding 1] [lindex $binding 2] [lindex $binding 4]
	}
	# arrêt du timer qui contrôle la mise à jour automatique de la page de stats HTML
	if {[set htmltimer [motus::timerexists {::motus::html_export "auto"}]] ne ""} { killtimer $htmltimer }
	# on importe les arrays car sinon les "set" du fichier config vont créer des variables locales
	variable wordlength_weight ; variable computed_wordlength_weight ; variable placed_hints
	eval [list source $::motus::main_config_file_full]
	set ::motus::profile_name $::motus::default_profile_name
	set ::motus::profile_file "[set ::motus::profile_name].cfg"
	set ::motus::profile_file_full "[set ::motus::config_path][set ::motus::profile_file]"
	if { $::motus::profile_file ne $::motus::main_config_file } {
		set ::motus::profile_description {}
		eval [list source $::motus::profile_file_full]
	}
	if { ![motus::post_config] } { return }
	if { ([channel get $::motus::motus_chan motus]) && (!$issilent) } {
		puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Le profil de configuration [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext] a été restauré par défaut."
	}
}

##### Supprime les hosts expirés de la liste des joueurs actifs
proc ::motus::check_for_expired_active_players {min hour day month year} {
	if { (!$::motus::status) || (![channel get $::motus::motus_chan motus]) } { return }
	foreach element $::motus::active_players_hostlist {
		if { [expr [clock seconds] - [lindex $element 1]] <= $::motus::player_cooldown_time } {
			lappend temp_list $element
		}
	}
	if { [::tcl::info::exists temp_list] } {
		set ::motus::active_players_hostlist $temp_list
	}
}

##### Supprime un joueur de la liste des joueurs actifs et de la liste des
##### votants lorsqu'il quitte le salon (part ou quit)
proc ::motus::user_has_left {nick host hand chan msg} {
	if { [set index [lsearch -exact -index 0 $::motus::active_players_hostlist $host]] != -1 } {
		set ::motus::active_players_hostlist [lreplace $::motus::active_players_hostlist $index $index]
	}
	if { ($::motus::vote_is_pending == 1) && ([set index [lsearch -exact -index 0 $::motus::has_voted $host]] != -1) } {
		set ::motus::has_voted [lreplace $::motus::has_voted $index $index]
	}
}

##### Affiche la liste des profils de configuration disponibles à la sélection par les joueurs participants
proc ::motus::list_users_selectable_profiles {nick host hand chan arg} {
	if {![channel get $::motus::motus_chan motus]} { return }
	puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Profils de configuration disponibles à la sélection par les joueurs participants : [code stop][code specialtext1]\002\002[set ::motus::profiles_selectable_by_users][code stop][code normaltext]. Profil actuellement utilisé : [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext]."	
}

##### Affiche la description du profil de configuration actuellement utilisé
proc ::motus::show_current_profile_description {} {
	if { (![channel get $::motus::motus_chan motus]) || ($::motus::profile_description eq "") } { return }
	if { !$::motus::status } {
		::motus::output_public_message 1 0 [code normaltext] "\037Description\037 : [set ::motus::profile_description]"
	} else {
		::motus::output_public_message 0 0 [code normaltext] "\037Description\037 : [set ::motus::profile_description]"
	}
}

##### Initialisation de la partie
proc ::motus::game_init {nick host hand chan arg} {
	set arg [lindex $arg 1]
	set isadmin [::motus::matchattr_ $hand $::motus::admin_flags $::motus::motus_chan]
	if {([channel get $::motus::motus_chan motus] == 0) && ($arg eq "")} {
		if {$isadmin} {
			puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Le Motus est actuellement désactivé. Tape  [code stop][code specialtext1]\002!motus on\002[code stop][code normaltext]  pour l'activer."
		}
		return
	}			
	if {$::motus::DEBUGMODE} { putlog "\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302\00312\00302" }
	if {$arg ne ""} {
		if {$arg eq "version"} {
			putserv "PRIVMSG $::motus::motus_chan :\002Motus v$::motus::version\002   [code 14]par Menz Agitat[code stop]"
			return
		} elseif {$isadmin} {
			::motus::admin_commands $nick $host $hand $chan $arg
			return
		} elseif { ![::motus::matchattr_ $hand $::motus::start_flags $chan] } {
			return
		}
	}
	if {$::motus::status == 0} {
		# on vérifie les autorisations d'accès aux différents fichiers
		set file_access_error 0
		if { ([::tcl::info::exists $::motus::stats_file]) && (![motus::is_readable $::motus::stats_file 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::stats_file]) && (![motus::is_writable $::motus::stats_file 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::playerstats_file]) && (![motus::is_readable $::motus::playerstats_file 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::playerstats_file]) && (![motus::is_writable $::motus::playerstats_file 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::scores_file]) && (![motus::is_readable $::motus::scores_file 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::scores_file]) && (![motus::is_writable $::motus::scores_file 0]) } { set file_access_error 1 }
		if { ![motus::is_readable $::motus::wordlist_file 0] } { set file_access_error 1 }
		if { ![motus::is_readable $::motus::dictionary_file 0] } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::scores_archive_file]) && (![motus::is_writable $::motus::scores_archive_file 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists "[set ::motus::html_template_path]index.html"]) && (![motus::is_readable "[set ::motus::html_template_path]index.html" 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists "[set ::motus::html_template_path]style.css"]) && (![motus::is_readable "[set ::motus::html_template_path]style.css" 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::champ_file]) && (![::tcl::info::exists $::motus::playerstats_file]) && (![motus::is_readable $::motus::champ_file 0]) } { set file_access_error 1 }
		if { ([::tcl::info::exists $::motus::finder_file]) && (![::tcl::info::exists $::motus::playerstats_file]) && (![motus::is_readable $::motus::finder_file 0]) } { set file_access_error 1 }
		if { $file_access_error } { return }
		::motus::convert_player_stats_to_v2_2_if_needed
		# on charge toutes les statistiques en mémoire (ainsi que les scores au passage)
		::motus::stats do read.stats - - -
		variable motencoursdedebug 1
		variable idle 0
		::motus::debugg 0
		if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Une partie de Motus a été lancée par\003 ${nick}!$host \00314(\003\002\002$hand\00314) sur \003\002\002$::motus::motus_chan\00314. On initialise les variables et on charge la liste de mots en mémoire.\003" }
		if { $nick ne $::botnick } {
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Chargement des données, veuillez patienter..."
		}
		set ::motus::status 1
		# chargement de la liste de mots		
		::motus::charge_listemots
		# chargement du dictionnaire de vérification des mots
		::motus::charge_dico
		if { $::motus::achievements_enabled } {
			# on construit l'array qui va permettre de surveiller quand un joueur accomplit un haut fait de total_score
			variable score_achievements_stages
			array set score_achievements_stages [list 0 -[set indecent_limit [expr 100000000 * ( $::motus::said_lost_points + $::motus::inexistant_lost_points + $::motus::null_lost_points )]] 1 1000 2 5000 3 10000 4 20000 5 50000 6 100000 7 200000 8 500000 9 1000000 10 2000000 11 5000000 12 10000000 13 20000000 14 50000000 15 100000000 16 $indecent_limit]
			# on construit l'array qui va permettre de surveiller quand un joueur accomplit un haut fait de rapidité
			variable quickness_achievements_stages
			array set quickness_achievements_stages {0 9999 1 30 2 10 3 5 4 3 5 2 6 0}
		}
		if { $::motus::min_word_length != $::motus::max_word_length } {
			variable minmaxlength "[set ::motus::min_word_length] à [set ::motus::max_word_length]"
		} else {
			variable minmaxlength "$::motus::min_word_length"
		}
		# création d'une liste d'index en ordre aléatoire pour les annonces inter-round
		variable announce_indexes [::motus::lrandomize [lsearch -all $::motus::announce_statements *]]
		variable current_announce_index 0
		if { $nick ne $::botnick } {
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Le Motus a été activé par [code stop][code specialtext1]\002\002[set nick][code stop][code normaltext]. Nous jouons actuellement avec [code stop][code specialtext1]\002\002[set ::motus::totalmots][code stop][code normaltext] mots de [code stop][code specialtext1]\002\002[set minmaxlength][code stop][code normaltext] lettres et les propositions sont vérifiées grâce au dictionnaire officiel du Scrabble. Le profil de configuration [code stop][code specialtext1]\002\002[set ::motus::profile_name][code stop][code normaltext] a été sélectionné par défaut.[code stop]"
		} else {
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Nous jouons actuellement avec [code stop][code specialtext1]\002\002[set ::motus::totalmots][code stop][code normaltext] mots de [code stop][code specialtext1]\002\002[set minmaxlength][code stop][code normaltext] lettres."
		}
		bind pubm -|- "$::motus::motus_chan *" ::motus::check_response
		bind pubm $::motus::stop_flags "$::motus::motus_chan %$::motus::stop_cmd%" ::motus::game_end
		bind pubm $::motus::next_flags "$::motus::motus_chan %$::motus::next_cmd%" ::motus::next_one
		bind pubm $::motus::repeat_flags "$::motus::motus_chan %$::motus::repeat_cmd%" ::motus::repete
		bind pubm $::motus::hint_flags "$::motus::motus_chan %$::motus::hint_cmd%" ::motus::hint
		bind nick - "$::motus::motus_chan *" ::motus::nickchange
		bind join -|- "$::motus::motus_chan *" ::motus::onjoin
		bind evnt - disconnect-server {motus::silent_stop 0}
		if { ($::motus::advertise) && ($nick ne $::botnick) } {
			foreach element $::motus::advertise_targets {
				puthelp "PRIVMSG $element :[code advertise]Une partie de [code stop][code advertise_special1]\002Motus\002[code stop][code advertise] vient d'être lancée par [code stop][code advertise_special2]\002\002[set nick][code stop][code advertise] sur le chan [code stop][code advertise_special2]\002\002[set ::motus::motus_chan][code stop][code advertise]. Tape  [code stop][code advertise_special2]\002/join $::motus::motus_chan\002[code stop][code advertise]  pour rejoindre la partie.[code stop]"
			}
		}
		::motus::motsuivant
	}
}

##### Arrêt du jeu demandé
proc ::motus::game_end {nick host hand chan args} {
	if { $::motus::status == 0 } {
		return
	} else {
		set ::motus::status 0
		putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]La partie a été arrêtée par [code stop][code specialtext1]\002\002[set nick][code stop][code normaltext].[code stop]"
		::motus::cleanup
		variable pending_profile_change 0
		if { ($::motus::profile_name ne $::motus::default_profile_name) && ($::motus::restore_default_profile_at_game_end) } {
			::motus::reapply_default_profile 0
		}
		if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Jeu terminé, ressources mémoire libérées.\003" }
		return
	}
}

##### Arrêt du jeu en cas d'inactivité des joueurs
proc ::motus::idle_stop {} {
	if { $::motus::status == 0 } {
		return
	} else {
		set ::motus::status 0
		puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Le Motus s'est arrêté après [code stop][code specialtext1]\002\002[set ::motus::idle_auto_stop][code stop][code normaltext] rounds sans aucune proposition. Tape  [code stop][code specialtext1]\002$::motus::start_cmd\002[code stop][code normaltext]  pour relancer la partie.[code stop]"
		::motus::cleanup
		variable pending_profile_change 0
		if { ($::motus::profile_name ne $::motus::default_profile_name) && ($::motus::restore_default_profile_at_game_end) } {
			::motus::reapply_default_profile 0
		}
		if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Jeu terminé après $::motus::idle_auto_stop rounds sans propositions, ressources mémoire libérées.\003" }
	}
}

##### Arrêt du jeu silencieux
proc ::motus::silent_stop {restarting evnt_type} {
	if { $::motus::status == 0 } {
		return
	} else {
		set ::motus::status 0
		# si le jeu a été arrêté suite à un vote pour changer de profil de difficulté, on préserve la valeur de $::motus::vote_is_pending
		if { $restarting } {
			set shadow_vote_is_pending $::motus::vote_is_pending
			::motus::cleanup
			set ::motus::vote_is_pending $shadow_vote_is_pending
		} else {
			::motus::reapply_default_profile 1
			::motus::cleanup
		}		
		if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Le jeu s'est arrêté, désallocation des ressources.\003" }
	}
}

##### Chargement de la liste de mots
proc ::motus::charge_listemots {} {
	variable listemots
	array set listemots {}
	set wordlist_file_channel [open $::motus::wordlist_file r]
	for { set counter $::motus::min_word_length } { $counter <= $::motus::max_word_length } { incr counter } {
		if { $counter >= $::motus::min_word_length } {
			for { set subcounter 1 } { $subcounter <= $::motus::wordlist_length_offsets($counter) } { incr subcounter } {
				lappend listemots($counter) [gets $wordlist_file_channel]
			}
			lappend totalmots_tmp "+ [llength $listemots($counter)]"
		} else {
			for { set subcounter 1 } { $subcounter <= $::motus::wordlist_length_offsets($counter) } { incr subcounter } {
				gets $wordlist_file_channel
			}
		}
	}
	close $wordlist_file_channel
	variable totalmots [expr [join $totalmots_tmp]]
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Liste de\003 $totalmots\00314 mots chargée en mémoire." }
}

##### Chargement de la liste de vérification
proc ::motus::charge_dico {} {
	variable listemotsverif ""
	set ods6_file_channel [open $::motus::dictionary_file r]
	for { set counter $::motus::min_word_length } { $counter <= $::motus::max_word_length } { incr counter } {
		if { $counter >= $::motus::min_word_length } {
			for { set subcounter 1 } { $subcounter <= $::motus::dico_length_offsets($counter) } { incr subcounter } {
				lappend listemotsverif [gets $ods6_file_channel]
			}
		} else {
			for { set subcounter 1 } { $subcounter <= $::motus::dico_length_offsets($counter) } { incr subcounter } {
				gets $ods6_file_channel
			}
		}
	}
	close $ods6_file_channel
	variable totalmotsverif [llength $listemotsverif]
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Liste de vérification de \003\002\002$totalmotsverif\00314 mots chargée en mémoire." }
}

##### Choisit un mot au hasard et initialise le masque
proc ::motus::choisit_mot {} {
	variable totalmots
	variable listemots
	variable masque ""
	variable motencoursdedebug
	# on choisit un nombre au hasard entre 1 et $::motus::total_wordlength_weight
	# et on choisit une longueur de mot en fonction de son poids
	set length_weight [expr [rand [expr $::motus::total_wordlength_weight + 1]]]
	for { set counter $::motus::min_word_length } { $counter <= $::motus::max_word_length } { incr counter } {
		if { $length_weight <= [lindex [split $::motus::computed_wordlength_weight($counter) ","] 1] } {
			set chosen_wordlength $counter
			set counter 100
		}
	}
	# on choisit un mot au hasard
	variable motchoisi_raw [lindex $listemots($chosen_wordlength) [rand [llength $listemots($chosen_wordlength)]]]
	while { $motchoisi_raw eq $motencoursdedebug } {
		variable motchoisi_raw [lindex $listemots($chosen_wordlength) [rand [llength $listemots($chosen_wordlength)]]]
	}
	variable motencoursdedebug $motchoisi_raw
	variable motchoisi [split [motus::formate_mot $motchoisi_raw] {}]
	# on crée un masque "_ _ _ _ _" pour cacher les lettres du mot
	regsub -all -- {[aA-zZ]} $motchoisi "_" masque
	# on place des lettres indices si nécessaire
	variable hints [::tcl::string::map "4 $::motus::placed_hints(4) 5 $::motus::placed_hints(5) 6 $::motus::placed_hints(6) 7 $::motus::placed_hints(7) 8 $::motus::placed_hints(8) 9 $::motus::placed_hints(9) 10 $::motus::placed_hints(10) 11 $::motus::placed_hints(11) 12 $::motus::placed_hints(12) 13 $::motus::placed_hints(13) 14 $::motus::placed_hints(14) 15 $::motus::placed_hints(15)" [llength $::motus::masque]]
	if { ($::motus::hints > 0) } {
		for { set counter 0 } { $counter < $::motus::hints } { incr counter } {
			set blank_positions [lsearch -all $::motus::masque "_"]
			set hint_position [lindex $blank_positions [rand [llength $blank_positions]]]
			variable masque [lreplace $masque $hint_position $hint_position [lindex [split [motus::toupper $::motus::motchoisi_raw] ""] $hint_position]]
		}
	}
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Mot choisi au hasard :\003 $motchoisi | \00314masque :\003 $masque" }
	return
}

##### Affiche le mot à trouver
proc ::motus::affiche_mot {arg} {
	if {$arg eq "hint"} {
		::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]un indice...[code stop]       [code gimmick]::::|   [code stop][code commonletter]\002$::motus::masque\002[code stop][code gimmick]   |::::[code stop]" 
		if { [lsearch $::motus::masque "_"] == -1 } { ::motus::putqueue "PRIVMSG $::motus::motus_chan :[code warning]Toutes les lettres sont maintenant placées ! Qui sera le plus rapide ?[code stop]" }
	} else {
		::motus::putqueue "PRIVMSG $::motus::motus_chan :[code gimmick]::::|   [code stop][code commonletter]\002$::motus::masque\002[code stop][code gimmick]   |::::[code stop]  [code normaltext]([llength $::motus::masque] lettres)[code stop]"
	}
}

##### Répète le masque du mot à trouver
proc ::motus::repete {nick host hand chan args} {
	::motus::affiche_mot "repeat"
}

##### Passe au mot suivant
proc ::motus::next_one {nick host hand chan args} {
	::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]On passe au mot suivant à la demande de [code stop][code specialtext1]\002\002[set nick][code stop]"
	variable idle 0
	if { $::motus::pending_profile_change } {
		::motus::apply_player_voted_profile
		return
	}
	::motus::motsuivant
}

##### Affiche un indice supplémentaire
proc ::motus::hint {nick host hand chan arg} {
	if {[motus::utimerexists {::motus::motsuivant}] ne ""} { return }
	variable masque
	variable auto_hints_given
	if { [set blank_positions [lsearch -all $::motus::masque "_"]] ne "" } {
		# Si on a choisi de ne pas donner automatiquement d'indice au cas où il ne reste plus qu'une lettre à trouver, on interromp
		if { ([llength $blank_positions] == 1) && ($::motus::give_last_hint == 0) && ($arg eq "auto") } { return }
		set hint_position [lindex $blank_positions [rand [llength $blank_positions]]]
		variable masque [lreplace $masque $hint_position $hint_position [lindex [split [motus::toupper $::motus::motchoisi_raw] ""] $hint_position]]
		::motus::affiche_mot "hint"
		if {[set hinttimer [motus::utimerexists {::motus::hint - - - - auto}]] ne ""} { killutimer $hinttimer }
		if {$arg eq "auto"} {
			incr ::motus::auto_hints_given
		}
		# Si le nombre d'indices automatiques déjà donnés est inférieur au nombre maximum
		# d'indices automatiques ET qu'il reste PLUS DE $::motus::hint_time secondes de temps
		# de jeu dans le round en cours, alors on relance un timer d'indice automatique.
		if { ($::motus::auto_hints_given < $::motus::max_hints) && ([lindex [lsearch -inline [utimers] "* ::motus::timeout *"] 0] > $::motus::hint_time) } {
			utimer $::motus::hint_time {::motus::hint - - - - auto}
		}
	} else {
		variable auto_hints_given $::motus::max_hints
		if {$arg ne "auto"} {
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Toutes les lettres sont en place.[code stop]"
		}
	}
	return
}

##### Un joueur propose un mot
proc ::motus::check_response {nick host hand chan arg} {
	variable idle
	variable listemotsverif
	variable motchoisi
	variable masque
	variable dejadit
	array set dejadit {}
	set arg [motus::strip_codes_and_spaces $arg]
	# si la proposition contient plusieurs mots, on l'ignore
	if { [regexp {[^\s]\s[^\s]} $arg] } { return }
	# si la proposition n'est pas constituée exclusivement de caractères alphabétiques, on l'ignore
	if { [::tcl::string::is alpha $arg] != 1 } { return }
	# mise en majuscules et suppression des accents éventuels
	set arg [motus::formate_mot $arg]
	variable proposition [split $arg {}]
	# si la proposition ne fait pas la bonne longueur, on l'ignore.
	set proplen [llength $proposition]
	if { $proplen != [llength $motchoisi] } { return }
	### arrivé à ce stade, on suppose que la proposition est valide (bonne longueur)
	#
	# Si le joueur vient de changer de nick, on transfère ses stats et on réévalue les records
	# ( array de la forme nickchange_array(clean new nick) = clean old nick )
	if {[::tcl::info::exists ::motus::nickchange_array([set cleannick [motus::clean_nick $nick]])]} {
		::motus::stats do rename.player $::motus::nickchange_array($cleannick) $cleannick write
		unset ::motus::nickchange_array($cleannick)
	}
	# on remet à 0 le compteur d'arrêt de partie en cas d'inactivité
	variable idle 0
	set activity_triggered 0
	# si auto_hint_mode = 1, on arrête le timer qui donne des indices en cas d'inactivité
	if { ($::motus::auto_hint_mode == 1) && ([set hinttimer [motus::utimerexists {::motus::hint - - - - auto}]] ne "") } {
		killutimer $hinttimer
		set activity_triggered 1
	}
	::motus::stats update player.total_words $nick 1 dontwrite
	if { $::motus::achievements_enabled } { ::motus::announce_achievements total_words $cleannick [lindex $::motus::player_stats([::tcl::string::tolower $cleannick]) 4] }
	# si le mot proposé n'existe pas...
	if { [lsearch $listemotsverif [join $proposition ""]] == -1 } {
		if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Le mot\003 $proposition \00314est invalide.\003" }
		::motus::stats update player.failures $nick 1 dontwrite
		if { ($::motus::lose_points) && ($::motus::inexistant_lost_points != 0) } {
			::motus::score_update $nick $host -$::motus::inexistant_lost_points
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Le mot [code stop][code specialtext1]\002[join $proposition ""]\002[code stop][code normaltext] est invalide.  [code lostpoints]-[set ::motus::inexistant_lost_points]pt[motus::plural $::motus::inexistant_lost_points][code stop]"
		} else {
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Le mot [code stop][code specialtext1]\002[join $proposition ""]\002[code stop][code normaltext] est invalide.[code stop]"
		}
		# on relance le timer pour donner des indices en cas d'inactivité des joueurs
		if { ($::motus::auto_hint_mode == 1) && ($::motus::auto_hints_given < $::motus::max_hints) && ([lindex [lsearch -inline [utimers] "* ::motus::timeout *"] 0] > $::motus::hint_time) } {
			utimer $::motus::hint_time {::motus::hint - - - - auto}
		}
		::motus::stats do write.stats players - -
		::motus::stats do write.stats game - -
		return
	}
	if { $::motus::players_can_change_profile } {
		# s'il n'y figure pas déjà, on ajoute le host du joueur à la liste des joueurs actifs
		if { [set index [lsearch -exact -index 0 $::motus::active_players_hostlist $host]] == -1 } {
			lappend ::motus::active_players_hostlist [list $host [clock seconds]]
		# si le joueur figure déjà dans la liste, on met à jour le temps de la dernière activité
		} else {
			set ::motus::active_players_hostlist [lreplace $::motus::active_players_hostlist $index $index [list $host [clock seconds]]]
		}
	}
	# à ce stade, la proposition est valide
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Proposition valide détectée :\003 $proposition" }
	# si la proposition EST le mot à deviner alors c'est gagné !
	if { $arg eq [join $motchoisi ""] } {
		if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 ${nick}\00314 (\003 $hand \00314) a trouvé la bonne réponse, il s'agissait bien du mot\003 $arg" }
		::motus::gagne $nick $host $hand $::motus::motus_chan
	# sinon on analyse la proposition
	} else {
		set motchoisi_temp $motchoisi
		set proposition_temp $proposition
		set ptsbienplaces 0
		# on compare lettre par lettre à la recherche des lettres BIEN placées
		for { set counter 0 } { $counter < $proplen } { incr counter } {
			# lettre en cours de comparaison
			set lettreencours [lindex $proposition_temp $counter]
			# position (si elle existe) de la lettre en cours de comparaison dans le mot à deviner
			if { $lettreencours eq [lindex $motchoisi $counter] } {
				set matchletterpos $counter
			} else {
				set matchletterpos [lsearch $motchoisi_temp $lettreencours]
			}
			# si la lettre en cours de comparaison existe ET qu'elle se trouve à la bonne position
			if { $matchletterpos == $counter } {
				set motchoisi_temp [lreplace $motchoisi_temp $matchletterpos $matchletterpos "+"]
				set proposition_temp [lreplace $proposition_temp $counter $counter "-"]
				variable proposition [lreplace $proposition $counter $counter "[code stop][code letterplaced][set lettreencours][code letterplacedend][code commonletter]"]
				# on compte les points pour les lettres bien placées (seulement la 1ère fois)
				if {[lindex $masque $matchletterpos] eq "_"} {
					set ptsbienplaces [expr $ptsbienplaces + $::motus::pts_letter_placed]
					::motus::stats update player.valid_letters $nick 1 dontwrite
					# si auto_hint_mode = 2, on arrête le timer qui donne des indices en cas d'inactivité
					if { ($::motus::auto_hint_mode == 2) && (!$activity_triggered) && ([set hinttimer [motus::utimerexists {::motus::hint - - - - auto}]] ne "") } {
						killutimer $hinttimer
						set activity_triggered 1
					}
				}
				variable masque [lreplace $masque $matchletterpos $matchletterpos "[lindex [split [motus::toupper $::motus::motchoisi_raw] ""] $counter]"]
				if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314La lettre\003 $lettreencours \00314en position\003 $counter\00314 dans la proposition est bien placée. L'état du mot en cours de traitement devient\003 $motchoisi_temp\00314, le masque devient\003 $masque \00314et la proposition devient\003 $proposition" }
			}
		}
		set ptsmalplaces 0
		# on compare lettre par lettre à la recherche des lettres MAL placées
		for { set counter 0 } { $counter < $proplen } { incr counter } {
			# lettre en cours de comparaison
			set lettreencours [lindex $proposition_temp $counter]
			# position (si elle existe) de la lettre en cours de comparaison dans le mot à deviner
			set matchletterpos [lsearch $motchoisi_temp $lettreencours]
			# si la lettre en cours de comparaison existe ET qu'elle NE se trouve PAS à la bonne position
			if { ($matchletterpos != -1) && ($matchletterpos != $counter) } {
				set motchoisi_temp [lreplace $motchoisi_temp $matchletterpos $matchletterpos "+"]
				set proposition_temp [lreplace $proposition_temp $counter $counter "-"]
				variable proposition [lreplace $proposition $counter $counter "[code stop][code letterexists][set lettreencours][code letterexistsend][code commonletter]"]
				::motus::stats update player.misplaced_letters $nick 1 dontwrite
				set ptsmalplaces [expr $ptsmalplaces + $::motus::pts_letter_found]
				if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314La lettre\003 $lettreencours \00314en position\003 $counter\00314 dans la proposition est mal placée (la bonne position est\003 $matchletterpos\00314). L'état du mot en cours de traitement devient\003 $motchoisi_temp\00314, le masque devient\003 $masque \00314et la proposition devient\003 $proposition" }
			}
		}
		# on vérifie que le mot n'a pas déjà été proposé
		set dejadit_tmp [::tcl::string::tolower [join $proposition ""]]
		if { [lsearch -exact [array names dejadit] $dejadit_tmp] != -1 } {
			::motus::stats update player.failures $nick 1 dontwrite
			if { ($::motus::lose_points) && ($::motus::said_lost_points != 0)} {
				# si le mot a déjà été proposé il y a plus de 2 secondes ou s'il a déjà été proposé par le même joueur, on pénalise par une perte de points
				if { ([clock seconds] >= [expr [lindex $::motus::dejadit($dejadit_tmp) 1] + 2]) || ([lindex $::motus::dejadit($dejadit_tmp) 0] == $cleannick) } {
					::motus::score_update $nick $host -$::motus::said_lost_points
					set ptsproposition "[code lostpoints]-[set ::motus::said_lost_points]pt[motus::plural $::motus::said_lost_points][code stop] [code normaltext](déjà proposé par [code stop][code specialtext1]\002\002[motus::restore_nick [lindex $::motus::dejadit($dejadit_tmp) 0]][code stop][code normaltext])[code stop]"
				# sinon on le signale mais on n'enlève pas de points
				} else {
					set ptsproposition "[code lostpoints]\002\0020pt[code stop] [code normaltext](déjà proposé par [code stop][code specialtext1]\002\002[motus::restore_nick [lindex $::motus::dejadit($dejadit_tmp) 0]][code stop][code normaltext] il y a moins de 2 secondes)[code stop]"
				}
			} else {
				set ptsproposition "[code normaltext](déjà proposé par [code stop][code specialtext1]\002\002[motus::restore_nick [lindex $::motus::dejadit($dejadit_tmp) 0]][code stop][code normaltext])[code stop]"
			}
		# sinon on compte les points
		} else {
			set dejadit($dejadit_tmp) [list $cleannick [clock seconds]]
			if { [set ptsproposition [expr $ptsbienplaces + $ptsmalplaces]] != 0 } {
				::motus::score_update $nick $host $ptsproposition
				set ptsproposition "[set ptsproposition]pt[motus::plural $ptsproposition]"
			} else {
				if { ($::motus::lose_points) && ($::motus::null_lost_points != 0) } {
					::motus::score_update $nick $host -$::motus::null_lost_points
					set ptsproposition "[code lostpoints]-[set ::motus::null_lost_points]pt[motus::plural $::motus::null_lost_points][code stop] [code normaltext](pénalité pour gain nul)[code stop]"
				} else {
					set ptsproposition ""
				}
			}
		}
		# on affiche le nouveau masque
		::motus::putqueue "PRIVMSG $::motus::motus_chan :[code gimmick]::::|  [code stop][code commonletter][variablebold][set proposition][variablebold][code stop][code gimmick]  |:::|  [code stop][code commonletter]\002$masque\002[code stop][code gimmick]  |::::[code stop] [code wonpoints]\002\002[set ptsproposition][code stop]"
		if { [lsearch $masque "_"] == -1 } { ::motus::putqueue "PRIVMSG $::motus::motus_chan :[code warning]Toutes les lettres sont maintenant placées ! Qui sera le plus rapide ?[code stop]" }
		# on relance le timer pour donner des indices en cas d'inactivité des joueurs
		if { ($activity_triggered) && ($::motus::auto_hints_given < $::motus::max_hints) && ([lindex [lsearch -inline [utimers] "* ::motus::timeout *"] 0] > $::motus::hint_time) } {
			utimer $::motus::hint_time {::motus::hint - - - - auto}
		}
	}
	::motus::stats do write.stats players - -
	::motus::stats do write.stats game - -
}

##### Avertissement quand le temps est bientôt écoulé (à 20% du temps restant)
proc ::motus::warning_timeout {} {
	::motus::putqueue "PRIVMSG $::motus::motus_chan :[code warning]:::[code stop]  [code normaltext]Il ne reste plus beaucoup de temps.[code stop]"
	return
}

##### Fin du temps imparti pour trouver un mot
proc ::motus::timeout {} {
	if { $::motus::status != 1 } {
		return
	} else {
		set ::motus::status 2
		if {[set hinttimer [motus::utimerexists {::motus::hint - - - - auto}]] ne ""} { killutimer $hinttimer }
		unbind pubm -|- "$::motus::motus_chan *" ::motus::check_response
		unbind pubm $::motus::next_flags "$::motus::motus_chan %$::motus::next_cmd%" ::motus::next_one
		unbind pubm $::motus::repeat_flags "$::motus::motus_chan %$::motus::repeat_cmd%" ::motus::repete
		unbind pubm $::motus::hint_flags "$::motus::motus_chan %$::motus::hint_cmd%" ::motus::hint
		::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Le temps est écoulé. Il fallait trouver le mot [code stop][code specialtext1]\002[motus::toupper $::motus::motchoisi_raw]\002[code stop]"
		if { $::motus::define_words == 1 } { ::motus::dico $::motus::motchoisi_raw }
		if { $::motus::pending_profile_change } {
			utimer $::motus::pause_time ::motus::apply_player_voted_profile
			return
		}
		utimer $::motus::pause_time ::motus::motsuivant
		# Fonction aléatoire pour décider si on affiche une annonce
		if { ($::motus::announces == 1) && ([expr [expr [clock clicks -milliseconds] % 100] + 1] <= $::motus::announce_freq) } { utimer $::motus::announce_delay {::motus::announce} }
	}
}

##### Un joueur a trouvé le mot !
proc ::motus::gagne {nick host hand chan} {
	set ::motus::status 2
	if {[set timetofind [motus::utimerexists {::motus::timeout}]] ne ""} { killutimer $timetofind }
	if {[set hinttimer [motus::utimerexists {::motus::hint - - - - auto}]] ne ""} { killutimer $hinttimer }
	if {[set timewarning [motus::utimerexists {::motus::warning_timeout}]] ne ""} { killutimer $timewarning }
	unbind pubm -|- "$::motus::motus_chan *" ::motus::check_response
	unbind pubm $::motus::next_flags "$::motus::motus_chan %$::motus::next_cmd%" ::motus::next_one
	unbind pubm $::motus::repeat_flags "$::motus::motus_chan %$::motus::repeat_cmd%" ::motus::repete
	unbind pubm $::motus::hint_flags "$::motus::motus_chan %$::motus::hint_cmd%" ::motus::hint
	set quickness [format "%.2f" [expr ([clock clicks -milliseconds]-$::motus::timestart) / 1000.00]]
	# on compte les points pour le mot trouvé + pour chaque lettre qui restait à trouver.
	set win_points [expr $::motus::pts_word_found + ([llength [lsearch -all $::motus::masque "_"]] * $::motus::pts_letter_placed)]
	# on ajoute des points bonus pour récompenser la rapidité
	if { $::motus::speed_reward } {
		set quickness_rate [expr ($quickness * 100) / $::motus::round_time]
		if { $quickness_rate <= 10 } {
			incr win_points $::motus::speed_bonus_10
		} elseif { $quickness_rate <= 20 } {
			incr win_points $::motus::speed_bonus_20
		} elseif { $quickness_rate <= 35 } {
			incr win_points $::motus::speed_bonus_35
		} elseif { $quickness_rate <= 50 } {
			incr win_points $::motus::speed_bonus_50
		}
	}
	# on met à jour le score
	::motus::score_update $nick $host $win_points
	::motus::putqueue "PRIVMSG $::motus::motus_chan :[code normaltext]Bravo [code stop][code specialtext2]\002\002[set nick][code stop][code normaltext], c'était le mot [code specialtext1]\002[code letterplaced][motus::toupper $::motus::motchoisi_raw][code letterplacedend]\002[code normaltext]. Tu l'as trouvé en [code stop][code specialtext2]\002\002[set quickness][code stop][code normaltext] secondes. Tu gagnes [code stop][code specialtext2]\002\002[set win_points][code stop][code normaltext] points, ce qui te fait un total de [code stop][code specialtext2]\002\002[motus::score $nick][code stop][code normaltext] points. Tu es classé [code stop][code specialtext2]\002\002[motus::score_place $nick nobold][code stop][code normaltext] sur [code stop][code specialtext2]\002\002[llength $::motus::scores][code stop][code normaltext].[code stop]"
	# on voice le joueur si la configuration du jeu le permet
	if { ($::motus::voice_players) && (((![isop $nick $chan]) && (![ishalfop $nick $chan])) || ($::motus::voice_staff)) } { putserv "MODE $::motus::motus_chan +v $nick" }
	set cleannick [motus::clean_nick $nick]
	set lowercleannick [::tcl::string::tolower $cleannick]
	set player_prev_best_time [lindex $::motus::player_stats($lowercleannick) 8]
	::motus::stats update player.best_time $nick $quickness dontwrite
	::motus::stats update player.finder_count $nick 1 dontwrite
	if { $::motus::achievements_enabled } {
		# on vérifie si un haut fait de rapidité a été accompli
		set counter 0
		while { ($quickness < $::motus::quickness_achievements_stages($counter)) && ($counter < 6) } { incr counter }
		incr counter -1
		if { (($quickness < $::motus::quickness_achievements_stages($counter)) && (($player_prev_best_time >= $::motus::quickness_achievements_stages($counter)))) || (!$player_prev_best_time) } {
			::motus::announce_achievements best_time $cleannick $quickness
		}
		# on vérifie si un haut fait a été accompli avec le nombre de rounds gagnés
		::motus::announce_achievements rounds_won $cleannick [lindex $::motus::player_stats($lowercleannick) 1]
	}
	if { $::motus::define_words == 1 } { after 0 [list ::motus::dico $::motus::motchoisi_raw] }
	if { $::motus::pending_profile_change } {
		utimer $::motus::pause_time ::motus::apply_player_voted_profile
		return
	}
	utimer $::motus::pause_time ::motus::motsuivant
	# Fonction aléatoire pour décider si on affiche une annonce
	if { ($::motus::announces == 1) && ([expr [expr [clock clicks -milliseconds] % 100] + 1] <= $::motus::announce_freq) } { utimer $::motus::announce_delay {::motus::announce} }
	return
}

##### On passe au mot suivant
proc ::motus::motsuivant {} {
	# ce qui suit évite d'avoir une double proposition (cas rare lié à un timing particulier avec un changement de profil voté par les joueurs)
	if { [::tcl::info::exists ::motus::nextword_lock] } {
		if { $::motus::DEBUGMODE } { putlog "\00304\002\[Motus - debug\]\002\003 \00314Une double proposition a été évitée.\003" }
		return
	} else {
		set ::motus::nextword_lock 1
		utimer 5 {unset ::motus::nextword_lock}
	}
	variable idle
	variable auto_hints_given
	if { ($idle < $::motus::idle_auto_stop) || ($::motus::idle_auto_stop == 0) } {
		incr idle
		set ::motus::status 1
		if { [array exists ::motus::dejadit] } { array unset ::motus::dejadit }
		::motus::choisit_mot
		::motus::affiche_mot new
		::motus::stats update stat.total_rounds 1 - write
		bind pubm -|- "$::motus::motus_chan *" ::motus::check_response
		bind pubm $::motus::next_flags "$::motus::motus_chan %$::motus::next_cmd%" ::motus::next_one
		bind pubm $::motus::repeat_flags "$::motus::motus_chan %$::motus::repeat_cmd%" ::motus::repete
		bind pubm $::motus::hint_flags "$::motus::motus_chan %$::motus::hint_cmd%" ::motus::hint
		if {[set timetofind [motus::utimerexists {::motus::timeout}]] ne ""} { killutimer $timetofind }
		if {[set timewarning [motus::utimerexists {::motus::warning_timeout}]] ne ""} { killutimer $timewarning }
		if {[set timerannounce [motus::utimerexists {::motus::announce}]] ne ""} { killutimer $timerannounce }
		if {[set hinttimer [motus::utimerexists {::motus::hint - - - - auto}]] ne ""} { killutimer $hinttimer }
		utimer $::motus::round_time {::motus::timeout}
		#timer annonce temps presque écoulé (à 20% du temps restant)
		utimer [expr $::motus::round_time - (($::motus::round_time * 20) / 100)] {::motus::warning_timeout}
		variable auto_hints_given "0"
		if { ($::motus::auto_hints_given < $::motus::max_hints) && ([lindex [lsearch -inline [utimers] "* ::motus::timeout *"] 0] > $::motus::hint_time) } {
			utimer $::motus::hint_time {::motus::hint - - - - auto}
		}
		set ::motus::timestart [clock clicks -milliseconds]
	} else {
		::motus::idle_stop
	}
}

##### On charge les scores
proc ::motus::lit_scores {} {
	set fichierscores [open $::motus::scores_file a+]
	seek $fichierscores 0 start
	variable scores [read -nonewline $fichierscores]
	close $fichierscores
	# Si le fichier scores est au format v1.x, on en fait un backup et
	# on le convertit au format v2.
	if {![regexp {^[0-9]*,(.*)$} $::motus::scores]} {
		::motus::trie_scores
	} else { 
		file copy -force -- $::motus::scores_file [set ::motus::scores_file].v1.old
		foreach element $::motus::scores {
			lappend scorestmp "[lindex [set item [split $element ","]] 1] [lindex $item 0]"
		}
		variable scores $scorestmp	
		::motus::trie_scores
		::motus::ecrit_scores
		putloglev o * "\00304\002\[Motus - info\]\002\003 Un fichier scores d'un ancien format (antérieur à la version 2.0 du Motus) a été trouvé et converti automatiquement au nouveau format. Une copie de sauvegarde de l'ancien fichier a été effectuée par sécurité, vous la trouverez ici : [set ::motus::scores_file].v1.old"
	}
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Les scores ont été chargés et classés par ordre décroissant (\003 $scores \00314).\003" }
}

##### On affiche les 10 meilleurs scores
proc ::motus::display_scores {nick host hand chan args} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	variable scores
	if { (![::tcl::info::exists scores]) || ($scores eq "") } { ::motus::stats do read.stats - - - }
	if { $scores ne "" } {
		set top10 ""
		for { set counter 1 } { $counter <= 10 } { incr counter } {
			set name_and_score [motus::score_pos $counter]
			if { [set current_name [motus::restore_nick [lindex $name_and_score 0]]] ne "" } {
				if { $counter != 1 } { set top10 [append top10 "[code scores4]|[code stop]"] }
				set top10 [append top10 "[code scores] $current_name \002[lindex $name_and_score 1] \002[code stop]"]
			}
		}
		puthelp "PRIVMSG $::motus::motus_chan :\002[code scores2]\037Top 10 des scores\037[code stop]\002 $top10"
	} else {
		puthelp "PRIVMSG $::motus::motus_chan :[code scores]Aucun score n'est enregistré.[code stop]"
	}
}

##### mise au singulier ou au pluriel selon la valeur
proc ::motus::plural {value} {
	if { ($value >= 2) || ($value <= -2) } { return "s" } { return "" }
}

##### Retourne le nick et le score de la n ième place dans les scores
proc ::motus::score_pos {place} {
	if {[set item [split [lindex $::motus::scores [expr $place - 1]]]] ne ""} {
		return $item
	}
}

##### Récupère le score de $nick
proc ::motus::score {nick} {
	set nick [motus::clean_nick $nick]
	return [lindex [lindex $::motus::scores [lsearch [::tcl::string::toupper $::motus::scores] "[::tcl::string::toupper $nick] *"]] 1]
}

##### Récupère la place de $nick dans le classement
proc ::motus::score_place {nick isbold} {
	if { $isbold eq "bold" } { set bold "\002" } { set bold "" }
	set nick [motus::clean_nick $nick]
	set place [expr [lsearch [::tcl::string::toupper $::motus::scores] "[::tcl::string::toupper $nick] *"] + 1]
	if { $place == 1 } {
		set place "[set bold][set place][set bold]er"
	} else {
		set place "[set bold][set place][set bold]ème"
	}
	return $place
}

##### Affiche un score individuel à la demande
proc ::motus::ask_score {nick host hand chan args} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	if { [motus::strip_codes_and_spaces [lindex [split [join $args]] 0]] ne "$::motus::score_cmd" } { return }
	variable scores
	if { (![::tcl::info::exists scores]) || ($scores eq "") } { ::motus::stats do read.stats - - - }
	set args [motus::strip_codes_and_spaces [lindex [split [join $args]] 1]]
	if { $args eq "" } { set args $nick }
	if { [set points [motus::score $args]] eq "" } {
		set points "aucun score"
	} else {
		set args [lindex [lindex $::motus::scores [lsearch [::tcl::string::toupper $::motus::scores] [::tcl::string::toupper "[motus::clean_nick $args] *"]]] 0]
		set points "\002$points\002pt[motus::plural $points]"
	}
	puthelp "PRIVMSG $::motus::motus_chan :[code scores]\002[motus::restore_nick $args]\002 : $points[code stop]"
	return
}

##### Affiche la position d'un joueur dans le classement
proc ::motus::ask_place {nick host hand chan args} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	if { [motus::strip_codes_and_spaces [lindex [split [join $args]] 0]] ne "$::motus::place_cmd" } { return }
	variable scores
	if { (![::tcl::info::exists scores]) || ($scores eq "") } { ::motus::stats do read.stats - - - }
	set args [motus::strip_codes_and_spaces [lindex [split [join $args]] 1]]
	if { $args eq "" } { set args $nick }
	if { [set place [motus::score_place $args bold]] eq "\0020\002ème" } {
		puthelp "PRIVMSG $::motus::motus_chan :[code scores]\002[motus::restore_nick $args]\002 : aucun score[code stop]"
	} else {
		set args [lindex [lindex $::motus::scores [lsearch [::tcl::string::toupper $::motus::scores] [::tcl::string::toupper "[motus::clean_nick $args] *"]]] 0]
		puthelp "PRIVMSG $::motus::motus_chan :[code scores]\002[motus::restore_nick $args]\002 : $place sur \002[llength $scores]\002[code stop]"
	}
	return
}

##### Affiche des statistiques sur un joueur
proc ::motus::ask_stat {nick host hand chan args} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	if { [motus::strip_codes_and_spaces [lindex [split [join $args]] 0]] ne "$::motus::stat_cmd" } { return }
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	set target [motus::strip_codes_and_spaces [lindex [split [join $args]] 1]]
	if { $target eq "" } { set target $nick }
	set target [motus::clean_nick $target]
	set lowercase_target [::tcl::string::tolower $target]
	variable player_stats
	set separator "[code stop][code scores3]|[code stop][code scores]"
	# si le joueur possède des stats personnelles
	if { [::tcl::info::exists player_stats($lowercase_target)] } {
		# nombre de rounds gagnés
		set rounds_won [lindex $player_stats($lowercase_target) 1]
		set rounds_won "rounds gagnés : \002$rounds_won\002"
		# score global
		set global_score [lindex $player_stats($lowercase_target) 3]
		set global_score "score total : \002$global_score\002"
		# mots proposés
		set words_submitted [lindex $player_stats($lowercase_target) 4]
		set words_submitted "mots proposés : \002$words_submitted\002"
		# échecs (mots déjà dits / mots inexistants) 
		set failures [lindex $player_stats($lowercase_target) 5]
		set failures "mots inexistants / déjà dits : \002$failures\002"
		# lettres bien placées 
		set placed_letters [lindex $player_stats($lowercase_target) 6]
		set placed_letters "lettres bien placées : \002$placed_letters\002"
		# lettres mal placées 
		set misplaced_letters [lindex $player_stats($lowercase_target) 7]
		set misplaced_letters "lettres mal placées : \002$misplaced_letters\002"
		# meilleur temps 
		if { [set best_time [lindex $player_stats($lowercase_target) 8]] != 0 } {
			set best_time "\002$best_time\002s"
		} else {
			set best_time "aucun"
		}
		set best_time "meilleur temps : $best_time"
		# points de hauts faits
		if { $::motus::achievements_enabled } { 
			set achievements_points "points de hauts faits : \002[motus::achievements_points $lowercase_target]/$::motus::max_achievements_points\002"
		} else {
			set achievements_points ""
		}
		# nombre de fois champion
		if { [set nbr_champ_titles [lindex $player_stats($lowercase_target) 2]] > 0 } {
			set champ_num "titres de champion de la semaine : \002$nbr_champ_titles\002"
		} elseif { [::tcl::string::tolower [lindex $::motus::stat_week_champ 1]] eq $lowercase_target } {
			set champ_num ""
		} else {
			set champ_num "jamais champion"
		}
		set own_stats "$rounds_won $separator $global_score $separator $words_submitted $separator $failures $separator $placed_letters $separator $misplaced_letters $separator $best_time $separator $achievements_points [if {$champ_num ne ""} { set dummy "$separator $champ_num" }]"
	# si le joueur ne possède pas de stats personnelles
	} else {
		set own_stats "pas de statistiques personnelles"
	}
	# titres et records
	if {[::tcl::string::tolower [lindex $::motus::stat_week_champ 1]] eq $lowercase_target} { lappend awards "Champion de la semaine ([set tmp_pts [lindex $::motus::stat_week_champ 0]] pt[motus::plural $tmp_pts])" }
	if {[::tcl::string::tolower [lindex $::motus::stat_last_week_champ 1]] eq $lowercase_target} { lappend awards "Champion de la semaine dernière ([set tmp_pts [lindex $::motus::stat_last_week_champ 0]] pt[motus::plural $tmp_pts])" }
	if {[::tcl::string::tolower [lindex [lindex $::motus::stat_all_time_top3 0] 0]] eq $lowercase_target} { lappend awards "Meilleur champion de tous les temps ([set tmp_pts [lindex [lindex $::motus::stat_all_time_top3 0] 1]] pt[motus::plural $tmp_pts])" }
	if {[::tcl::string::tolower [lindex [lindex $::motus::stat_all_time_top3 1] 0]] eq $lowercase_target} { lappend awards "2ème meilleur champion de tous les temps ([set tmp_pts [lindex [lindex $::motus::stat_all_time_top3 1] 1]] pt[motus::plural $tmp_pts])" }
	if {[::tcl::string::tolower [lindex [lindex $::motus::stat_all_time_top3 2] 0]] eq $lowercase_target} { lappend awards "3ème meilleur champion de tous les temps ([set tmp_pts [lindex [lindex $::motus::stat_all_time_top3 2] 1]] pt[motus::plural $tmp_pts])" }
	if {[::tcl::string::tolower [lindex $::motus::stat_most_champ 1]] eq $lowercase_target} { lappend awards "Détenteur du plus grand nombre de titres de champion" }
	if {[::tcl::string::tolower [lindex $::motus::stat_best_finder 1]] eq $lowercase_target} { lappend awards "Record du plus grand nombre de rounds gagnés" }
	if {[::tcl::string::tolower [lindex $::motus::stat_fastest_play 1]] eq $lowercase_target} { lappend awards "Joueur le plus rapide ([lindex $::motus::stat_fastest_play 0]s)" }
	::motus::output_public_message 0 0 [code scores] "\002[motus::restore_nick $target]\002 : $own_stats [if {(![::tcl::info::exists awards]) || ($awards eq "")} { set dummy "$separator aucun record " }]"
	if { ([::tcl::info::exists awards]) && ($awards ne "") } {
		set awards "[code scores]\037Titres détenus\037 : [join $awards " $separator "][code stop]"
		::motus::output_public_message 0 0 [code scores] $awards
	}
	return
}

##### Affiche les records du jeu
proc ::motus::ask_records {nick host hand chan args} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	if { [lindex [split [join $args]] 0] ne "$::motus::records_cmd" } { return }
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	set records "[code scores2]\037\002Records du Motus\002\037[code stop] [code scores]\037Champion de la semaine\037 : [motus::restore_nick [lindex $::motus::stat_week_champ 1]] ([set tmp_pts [lindex $::motus::stat_week_champ 0]] pt[motus::plural $tmp_pts])[code stop] \
[code scores]\037Champion de la semaine dernière\037 : [lindex $::motus::stat_last_week_champ 1] ([set tmp_pts [motus::restore_nick [lindex $::motus::stat_last_week_champ 0]]] pt[motus::plural $tmp_pts])[code stop] \
[code scores]\037Top3 des meilleurs champions\037 : [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 0] 0]] ([set tmp_pts [lindex [lindex $::motus::stat_all_time_top3 0] 1]] pt[motus::plural $tmp_pts]) [code stop][code scores3]/[code stop][code scores] [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 1] 0]] ([set tmp_pts [lindex [lindex $::motus::stat_all_time_top3 1] 1]] pt[motus::plural $tmp_pts]) [code stop][code scores3]/[code stop][code scores] [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 2] 0]] ([set tmp_pts [lindex [lindex $::motus::stat_all_time_top3 2] 1]] pt[motus::plural $tmp_pts])[code stop] \
[code scores]\037Plus grand nombre de titres de champion\037 : [motus::restore_nick [lindex $::motus::stat_most_champ 1]] ([lindex $::motus::stat_most_champ 0] titres)[code stop] \
[code scores]\037Plus grand nombre de rounds gagnés\037 : [motus::restore_nick [lindex $::motus::stat_best_finder 1]] ([lindex $::motus::stat_best_finder 0] rounds)[code stop] \
[code scores]\037Joueur le plus rapide\037 : [motus::restore_nick [lindex $::motus::stat_fastest_play 1]] ([lindex $::motus::stat_fastest_play 0] secondes)[code stop]"
	# on découpe la liste des records pour ne pas dépasser la limite de caractères par ligne
	set output_length [::tcl::string::length $records]
	set letter_index 0
	while {$letter_index < $output_length} {
		if {$output_length - $letter_index > $::motus::max_line_length} {
			set cut_index [::tcl::string::last "[code stop] " $records [expr $letter_index + $::motus::max_line_length]]		
		} else {
			set cut_index $output_length 
		}
		lappend output [::tcl::string::range $records $letter_index $cut_index]
		set letter_index $cut_index
	}
	foreach line $output {
		puthelp "PRIVMSG $::motus::motus_chan :[code scores]\002\002[set line][code stop]"
	}
}

##### Actualise le score de $nick
proc ::motus::score_update {nick host difference} {
	variable scores
	set cleannick [motus::clean_nick $nick]
	# si le joueur ne possède pas encore de score
	if { [set position_score [lsearch $::motus::scores "$cleannick *"]] == -1 } {
		lappend scores "${cleannick} [expr $difference]"
	# si le joueur possède déjà un score
	} else {
		variable scores [lreplace $scores $position_score $position_score "${cleannick} [expr [motus::score $cleannick] + $difference]"]
	}
	# si on détecte une double entrée dans les scores, on opère une fusion
	if {[llength [lsearch -regexp -all -inline [::tcl::string::tolower $::motus::scores] "^[set lowcasenick [::tcl::string::tolower $cleannick]] (.*)$"]] > 1} {
		if { $::motus::warn_on_fusion } { ::motus::putlog_split_line "\00304\002\[Motus - info\]\002\003 Il y a plus d'une entrée au nom de\00307 $nick\003\00314![getchanhost $nick] ([nick2hand $nick])\003 dans les scores, on les fusionne. Etat avant fusion : \00314$scores\003" }
		::motus::fusion_scores $nick $lowcasenick
	}
	::motus::trie_scores
	::motus::ecrit_scores
	set player_prev_total_score [lindex $::motus::player_stats($lowcasenick) 3]
	::motus::stats update player.global_score $nick $difference dontwrite
	# on vérifie si un haut fait a été accompli
	if { $::motus::achievements_enabled } {
		set player_total_score [expr $player_prev_total_score + $difference]
		set counter 0
		while { ($player_total_score >= $::motus::score_achievements_stages($counter)) && ($counter < 16) } { incr counter }
		incr counter -1
		if { ($player_prev_total_score < $::motus::score_achievements_stages($counter)) } {
			::motus::announce_achievements total_score $cleannick $::motus::score_achievements_stages($counter)
		}
	}
	# mise à jour de record.week_champ si nécessaire
	::motus::stats update record.week_champ $cleannick [motus::score $cleannick] dontwrite
	return
}

##### Trie les scores
proc ::motus::trie_scores {} {
	variable scores [lsort -integer -index 1 -decreasing $::motus::scores]
}

##### Fusionne les entrées en double de $nick dans les scores
proc ::motus::fusion_scores {nick lowcasenick} {
	variable scores
	set nick [motus::clean_nick $nick]
	set total 0
	foreach elem $::motus::scores {
		set name [lindex $elem 0]
		set score [lindex $elem 1]
		if { [::tcl::string::tolower $name] ne $lowcasenick } {
			lappend scorestemp $elem
		} else {
			incr total $score
		}
	}
	lappend scorestemp "[set nick] [set total]"
	variable scores $scorestemp
}

##### Fusion manuelle des scores et statistiques de 2 entrées différentes du même joueur.
proc ::motus::ask_fusion {nick host hand chan arg} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	set arg [split $arg]
	if { [lindex $arg 2] eq "" } {
		puthelp "PRIVMSG $::motus::motus_chan :\037Syntaxe\037 : \002$::motus::playersfusion_cmd\002 [code 14]<\002[code stop]nick1[code 14]\002> <\002[code stop]nick2[code 14]\002> \[\[\002[code stop]nick3[code 14]\002\] \[[code stop]...[code 14]\]\][code stop] [code 07]|[code stop] fusionne les scores et les statistiques de \002nick1\002, \002nick2\002, etc... dans \002nick1\002"
		return
	}
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	variable scores
	variable player_stats
	# on vérifie la validité de chaque nick passé en argument
	set targetnick [lindex $arg 1]
	if { ([set targetnick_index [lsearch [::tcl::string::tolower $::motus::scores] "[set lowercleantargetnick [::tcl::string::tolower [motus::clean_nick $targetnick]]] *"]] == -1) && (![::tcl::info::exists player_stats($lowercleantargetnick)]) } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code normaltext]Aucune entrée n'a été trouvée au nom de [code specialtext1]\002\002[set targetnick][code normaltext] dans les scores ou les statistiques."
		return
	}
	foreach sourcenick [lrange $arg 2 end] {
		# si sourcenick = targetnick, on passe
		if { $lowercleantargetnick eq [set lowercleansourcenick [::tcl::string::tolower [motus::clean_nick $sourcenick]]] } {
			puthelp "PRIVMSG $::motus::motus_chan :[code warning]::: [code specialtext1]\002\002[set sourcenick][code normaltext] a été ignoré car la cible ne peut être identique à la source."
			continue
		# si sourcenick existe déjà dans la liste des nicks à fusionner, on passe
		} elseif { ([::tcl::info::exists lowercleansourcenicks]) && ([lsearch $lowercleansourcenicks $lowercleansourcenick] != -1) } {
			continue
		# si sourcenick n'existe ni dans les scores, ni dans les stats, on continue
		} elseif { ([lsearch [::tcl::string::tolower $::motus::scores] "$lowercleansourcenick *"] == -1)
			&& (![::tcl::info::exists player_stats($lowercleansourcenick)])
		} then {
			puthelp "PRIVMSG $::motus::motus_chan :[code warning]::: [code specialtext1]\002\002[set sourcenick][code normaltext] a été ignoré car il n'existe aucune entrée à ce nom dans les scores ou les statistiques."
			continue
		# sinon on ajoute à la liste des lowercleansourcenicks à fusionner
		} else {
			lappend lowercleansourcenicks $lowercleansourcenick
		}
	}
	if { ![::tcl::info::exists lowercleansourcenicks] } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code normaltext]Il faut au moins une source valide pour effectuer une fusion."
		return
	} else {
		# on effectue la fusion des scores et statistiques sur chaque sourcenick valide
		set lowercleansourcenicks [lsort -unique $lowercleansourcenicks] 
		foreach lowercleansourcenick $lowercleansourcenicks {
			# fusion des scores
			if { ([set sourcenick_index [lsearch [::tcl::string::tolower $::motus::scores] "$lowercleansourcenick *"]] != -1) && ($targetnick_index != -1) } {
				lappend scores "[lindex [lindex $::motus::scores $targetnick_index] 0] [expr [lindex [lindex $::motus::scores $sourcenick_index] 1] + [lindex [lindex $::motus::scores $targetnick_index] 1]]"
				variable scores [lreplace $::motus::scores $targetnick_index $targetnick_index]
				# remarque : on reconsidère $sourcenick_index car en raison du lreplace ci-dessus, les index peuvent avoir changé.
				variable scores [lreplace $::motus::scores [set sourcenick_index [lsearch [::tcl::string::tolower $::motus::scores] "$lowercleansourcenick *"]] $sourcenick_index]
				::motus::trie_scores
				::motus::ecrit_scores
			}
			# fusion des statistiques
			if { ([::tcl::info::exists player_stats($lowercleantargetnick)]) && ([::tcl::info::exists player_stats($lowercleansourcenick)]) } {
				for { set counter 1 } { $counter <= 7 } { incr counter } {
					lappend temp_values [expr [lindex $player_stats($lowercleansourcenick) $counter] + [lindex $player_stats($lowercleantargetnick) $counter]]
				}
				set quickness0 [lindex $player_stats($lowercleantargetnick) 8]
				set quickness1 [lindex $player_stats($lowercleansourcenick) 8]
				if { $quickness0 == 0 } { set quickness $quickness1 } elseif { $quickness1 == 0 } { set quickness $quickness0 } else { set quickness [expr ($quickness0 < $quickness1)?$quickness0:$quickness1] }
				set player_stats($lowercleantargetnick) "[lindex $player_stats($lowercleantargetnick) 0] $temp_values $quickness"
				unset player_stats($lowercleansourcenick)
				unset temp_values
			}
		}
		::motus::stats do write.stats players - -
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]:::[code stop][code normaltext] Les scores et statistiques de [code specialtext1]\002\002[set targetnick] [if { [set nicklist [::motus::restore_nick [join [lrange $lowercleansourcenicks 0 end-1] "\017[code normaltext], [code specialtext1]\002\002"]]] eq "" } { set dummy "" } { set dummy "\017[code normaltext], [code specialtext1]\002\002[set nicklist] " }]\017[code normaltext]et [code specialtext1]\002\002[::motus::restore_nick [lindex $lowercleansourcenicks end]]\017[code normaltext] ont été fusionnés dans [code specialtext1]\002\002[set targetnick][code normaltext].[code stop]"
	}
}

##### Renommage manuel d'un joueur dans les scores et les statistiques personnelles
proc ::motus::ask_rename {nick host hand chan arg} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	set arg [split $arg]
	set arg1 [lindex $arg 2]
	if { ($arg1 eq "") || ([lindex $arg 3] ne "") } {
		puthelp "PRIVMSG $::motus::motus_chan :\037Syntaxe\037 : \002$::motus::playerrename_cmd\002 [code 14]<\002[code stop]ancien_nick[code 14]\002> <\002[code stop]nouveau_nick[code 14]\002>[code stop] [code 07]|[code stop] renomme \002ancien_nick\002 en \002nouveau_nick\002 dans les scores et les statistiques personnelles."
		return
	}
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	variable scores
	variable player_stats
	set arg0 [lindex $arg 1]
	if {[::tcl::string::tolower $arg0] eq [::tcl::string::tolower $arg1]} {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code stop][code 14]<[code specialtext1]\002nouveau_nick\002[code 14]>[code stop][code normaltext] doit être différent de [code stop][code 14]<[code specialtext1]\002ancien_nick\002[code 14]>[code stop]"
		return
	}
	if { ([set posarg0 [lsearch [::tcl::string::tolower $::motus::scores] "[set lowercleannick0 [::tcl::string::tolower [motus::clean_nick $arg0]]] *"]] == -1) && (![::tcl::info::exists player_stats($lowercleannick0)]) } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code normaltext]Aucune entrée n'a été trouvée au nom de [code specialtext1]\002\002[set arg0][code normaltext] dans les scores ou les statistiques."
		return
	}
	set cleannick1 [motus::clean_nick $arg1]
	if { ([lsearch [::tcl::string::tolower $::motus::scores] "[set lowercleannick1 [::tcl::string::tolower $cleannick1]] *"] != -1) || ([::tcl::info::exists player_stats($lowercleannick1)]) } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code normaltext]Une entrée existe déjà au nom de [code specialtext1]\002\002[set arg1][code normaltext] dans les scores ou les statistiques."
		return
	}
	# renommage dans les scores
	if { $posarg0 != -1 } {
		lappend scores "$cleannick1 [lindex [lindex $::motus::scores $posarg0] 1]"
		variable scores [lreplace $::motus::scores $posarg0 $posarg0]
		::motus::trie_scores
		::motus::ecrit_scores
	}
	# renommage dans les statistiques personnelles
	if { [::tcl::info::exists player_stats($lowercleannick0)] } {
		set player_stats($lowercleannick1) "$cleannick1 [lrange $player_stats($lowercleannick0) 1 8]"
		unset player_stats($lowercleannick0)
		::motus::stats do write.stats players - -
	}
	puthelp "PRIVMSG $::motus::motus_chan :[code warning]:::[code stop] [code specialtext1]\002\002[set arg0][code normaltext] a été renommé en [code specialtext1]\002\002[set arg1][code normaltext].[code stop]"
}

##### Recherche de joueurs dans les statistiques
proc ::motus::find_players {nick host hand chan arg} {
	if { [channel get $::motus::motus_chan motus] == 0 } { return }
	set arg [join [lrange [split $arg] 1 end]]
	if { $arg eq "" } {
		puthelp "PRIVMSG $::motus::motus_chan :\037Syntaxe\037 : \002[set ::motus::findplayers_cmd]\002 [code 14]<\002[code stop]masque_de_recherche[code 14]\002>[code stop] [code 07]|[code stop] affiche une liste des joueurs correspondant au masque de recherche dans les statistiques du jeu (jokers acceptés)."
		return
	}
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	set clean_arg [::motus::clean_nick $arg]
	set primary_search_results [lsearch -inline -nocase -all [array names ::motus::player_stats] $clean_arg]
	set final_search_results {}
	set counter 0
	foreach search_result $primary_search_results {
		incr counter
		lappend final_search_results [::motus::restore_nick [lindex $::motus::player_stats($search_result) 0]]
		if { $counter == $::motus::findplayer_max_results } { break }
	}
	if { ![set num_results [llength $final_search_results]] } {
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]:::[code stop][code normaltext] La recherche de [code specialtext1]\002\002[set arg][code normaltext] n'a donné aucun résultat."
	} elseif { $num_results == $::motus::findplayer_max_results } {
		::motus::output_public_message 0 0 {} "[code warning]:::[code stop][code normaltext] La recherche de [code specialtext1]\002\002[set arg][code normaltext] a donné [code specialtext1]\002\002[set num_results][code normaltext] résultat[::motus::plural $num_results]. Affichage des $::motus::findplayer_max_results premiers : [code stop][join $final_search_results " [code specialtext2]|[code stop] "]"
	} else {
		::motus::output_public_message 0 0 {} "[code warning]:::[code stop][code normaltext] La recherche de [code specialtext1]\002\002[set arg][code normaltext] a donné [code specialtext1]\002\002[set num_results][code normaltext] résultat[::motus::plural $num_results] : [code stop][join $final_search_results " [code specialtext2]|[code stop] "]"
	}
}

##### Ecriture des scores sur le disque
proc ::motus::ecrit_scores {} {
	if { ([::tcl::info::exists $::motus::scores_file]) && (![motus::is_writable $::motus::scores_file 1]) } { return }
	set fichierscores [open $::motus::scores_file w]
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Ecriture du fichier scores \00314 avec le contenu :\003 $::motus::scores" }
	puts -nonewline $fichierscores $::motus::scores
	close $fichierscores
}

##### Ecriture des scores dans l'historique
proc ::motus::archive_scores {} {
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	variable scores
	if { $::motus::stat_last_scores_reset != 0 } {
		set temp_last_scores_reset "du [strftime "%d/%m/%Y-%H:%M:%S" $::motus::stat_last_scores_reset] au "
	} else {
		set temp_last_scores_reset "du [strftime "%d/%m/%Y-%H:%M:%S" $::motus::stat_reference_time] au "
	}
	if { $scores ne "" } {
		set history "$temp_last_scores_reset[strftime "%d/%m/%Y-%H:%M:%S"] : [motus::restore_nick [join $scores " | "]]"
	} else {
		set history "$temp_last_scores_reset[strftime "%d/%m/%Y-%H:%M:%S"] : Aucun score n'a été enregistré durant cette période."
	}
	::motus::stats update stat.last_scores_reset [unixtime] - write
	set fichierscoresarchive [open $::motus::scores_archive_file a]
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Ecriture du fichier archive des scores à l'offset\003 [tell $fichierscoresarchive] \00314 avec le contenu :\003 $history" }
	puts $fichierscoresarchive $history
	close $fichierscoresarchive
}

##### Effacement des scores manuellement
proc ::motus::clear_scores {nick host hand chan args} {
		if {![channel get $::motus::motus_chan motus]} { return }
		::motus::backup_files 0 0 0 0 0
		::motus::archive_scores
		variable scores ""
		::motus::ecrit_scores
		puthelp "PRIVMSG $::motus::motus_chan :[code warning]\002Les scores du Motus ont été remis à zéro à la demande de $nick."
		return
}

##### Effacement des scores chaque semaine
proc ::motus::clear_scores_weekly {min hour day month year} {
	if { [lindex [ctime [unixtime]] 0] == [::tcl::string::map -nocase {lundi Mon mardi Tue mercredi Wed jeudi Thu vendredi Fri samedi Sat dimanche Sun} $::motus::clearscores_day] } {
		::motus::archive_scores
		variable scores ""
		::motus::ecrit_scores
		set current_time [split [lindex [ctime [unixtime]] 3] ":"]
		if { [channel get $::motus::motus_chan motus] == 1 } { puthelp "PRIVMSG $::motus::motus_chan :[code warning]\002Remise à zéro hebdomadaire des scores du Motus." }
	}
}

##### Backup des scores et statistiques
proc ::motus::backup_files {min hour day month year} {
	if { [file exists $::motus::scores_file] } { file copy -force -- $::motus::scores_file [set ::motus::scores_file].bak }
	if { [file exists $::motus::scores_archive_file] } { file copy -force -- $::motus::scores_archive_file [set ::motus::scores_archive_file].bak }
	if { [file exists $::motus::stats_file] } { file copy -force -- $::motus::stats_file [set ::motus::stats_file].bak }
	if { [file exists $::motus::playerstats_file] } { file copy -force -- $::motus::playerstats_file [set ::motus::playerstats_file].bak }
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 \00314Backup des scores et statistiques effectué.\003" }
}

##### Gestion des statistiques
# syntaxe de la procédure : ::motus::stats <command> <subcommand> <parameter1> <parameter2> <write_file>
# ----------------------------------------------------------------------------------------------------
# $command	$subcommand								$parameter1				$parameter2		$write_file
# do				read.stats								-									-							-										lecture des statistiques (lit également les scores + crée les fichiers de statistiques s'ils n'existent pas)
# do				write.stats								<game/players>		-							-										écriture des statistiques
# do				rename.player							<oldnick>					<newnick>			<write/dontwrite>		opère les modifications nécessaires dans les statistiques afin de suivre les changements de nick des joueurs
# do 				week.change								-									-							-										changement de semaine (roulement des statistiques)
# do 				reset											<nick>						-							-										remise à 0 de toutes les statistiques
# update		player.finder_count				<nick>						<incrément>		<write/dontwrite>		mise à jour du nombre de rounds gagnés par un joueur (appelle record.best_finder)
# update		player.champ_count				<nick>						<incrément>		<write/dontwrite>		mise à jour du nombre de fois champion d'un joueur (appelle record.most_champ)
# update		player.global_score				<nick>						<incrément>		<write/dontwrite>		mise à jour du score cumulé d'un joueur
# update		player.total_words				<nick>						<incrément>		<write/dontwrite>		mise à jour du nombre total de mots proposés par un joueur
# update		player.failures						<nick>						<incrément>		<write/dontwrite>		mise à jour du nombre d'échecs d'un joueur (tout ce qui fait perdre des points)
# update		player.valid_letters			<nick>						<incrément>		<write/dontwrite>		mise à jour du nombre cumulé de lettres bien placées par un joueur
# update		player.misplaced_letters	<nick>						<incrément>		<write/dontwrite>		mise à jour du nombre cumulé de lettres mal placées par un joueur
# update		player.best_time					<nick>						<temps>				<write/dontwrite>		mise à jour du meilleur temps d'un joueur si nécessaire (appelle record.fastest_play)
# update		record.best_finder				<nick>						<rounds>			<write/dontwrite>		mise à jour du record du nombre de rounds gagnés ($stat_best_finder) si nécessaire (appelé par player.finder_count)
# update		record.most_champ					<nick>						<titres>			<write/dontwrite>		mise à jour du record du nombre de fois champions ($stat_most_champ) si nécessaire (appelé par player.champ_count)
# update		record.fastest_play				<nick>						<temps>				<write/dontwrite>		mise à jour du record de rapidité ($stat_fastest_play) si nécessaire (appelé par player.best_time)
# update		record.week_champ					<nick>						<score>				<write/dontwrite>		mise à jour du champion de la semaine ($stat_week_champ) si nécessaire
# update		record.all_time_top3			<nick>						<score>				<write/dontwrite>		mise à jour du top3 des meilleurs champions ($stat_all_time_top3) si nécessaire
# update		stat.last_scores_reset		<valeur>					-							<write/dontwrite>		mise à jour de la date de la dernière remise à 0 des scores ($stat_last_scores_reset)
# update		stat.total_rounds					<incrément>				-							<write/dontwrite>		mise à jour du nombre total de rounds joués ($stat_total_rounds)
# structure player.stats : pseudo,rounds_gagnés,nbr_fois_champion,scoreglobal,nbr_mots_proposés,échecs,lettres_bien_placées,lettres_mal_placées,meilleur_temps
proc ::motus::stats {command subcommand parameter1 parameter2 write_file} {
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug - module de statistiques\]\002\003\00314 appel de\003 $command $subcommand $parameter1 $parameter2 $write_file\00314 depuis\003 [lindex [::tcl::info::level 1] 0]\\[lindex [::tcl::info::level -1] 0]" }
	variable stats
	variable player_stats
	# si la procédure stats est appelée pour autre chose que pour lire ou écrire les fichiers
	# de statistiques, cela signifie la mise à jour d'une ou plusieurs statistiques.
	# Par conséquent, on met à jour la valeur last.update (stat_last_update)
	if {($subcommand ne "read.stats") && ($subcommand ne "write.stats")} {
		variable stat_last_update [unixtime]
		variable stats [lreplace $::motus::stats [set index [lsearch -regexp $::motus::stats {^\[last.update\](.*)}]] $index "\[last.update\] $::motus::stat_last_update"]
	}
	switch -- $command {
		"do" {
			switch -- $subcommand {
				"read.stats" {
					# si les scores ne sont pas déjà chargés, on lit le fichier scores
					if { (![::tcl::info::exists ::motus::scores]) || ($::motus::scores eq "") } { ::motus::lit_scores }
					# si un fichier motus.stats existe déjà on le lit
					if {[file exists $::motus::stats_file]} {
						set fichierstats [open $::motus::stats_file r]
						set read_stats [split [read -nonewline $fichierstats] "\n"]
						close $fichierstats
						set make_stats 0
						# si l'entête du fichier lu est invalide, on le réécrit intégralement
						if {[::tcl::string::first !#v [join [lindex $read_stats 0]]] != 0} { 
							putloglev o * "\00304\002\[Motus - erreur\]\002\003 le fichier de statistiques du jeu est corrompu. Recréation d'un nouveau fichier."
							set make_stats 1
						}
					# sinon on en crée un
					} else {
						set make_stats 1
					}
					if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug - module de statistiques\]\002\003 make_stats : \00314$make_stats\003 \00307|\003 read_stats : \00314$read_stats\003" }
					if {$make_stats} {
						lappend stats "!#v$::motus::version:$::botnick" "\[reference.time\] [unixtime]" "\[last.update\] [unixtime]" "\[last.scores.reset\] 0" "\[week.champ\] 0 personne" "\[last.week.champ\] 0 personne" "\[all.time.top3\] \{personne 0\} \{personne 0\} \{personne 0\}" "\[most.champ\] 0 personne" "\[best.finder\] 0 personne" "\[fastest.play\] 0 personne" "\[total.rounds\] 0"
					} else {
						variable stats $read_stats
					}
					variable stat_reference_time [lindex [lindex $stats [lsearch -regexp $stats {^\[reference.time\](.*)}]] 1]
					variable stat_last_update [lindex [lindex $stats [lsearch -regexp $stats {^\[last.update\](.*)}]] 1]
					variable stat_last_scores_reset [lindex [lindex $stats [lsearch -regexp $stats {^\[last.scores.reset\](.*)}]] 1]
					variable stat_week_champ [lrange [lindex $stats [lsearch -regexp $stats {^\[week.champ\](.*)}]] 1 2]
					variable stat_last_week_champ [lrange [lindex $stats [lsearch -regexp $stats {^\[last.week.champ\](.*)}]] 1 2]
					variable stat_all_time_top3 [lrange [lindex $stats [lsearch -regexp $stats {^\[all.time.top3\](.*)}]] 1 3]
					variable stat_most_champ [lrange [lindex $stats [lsearch -regexp $stats {^\[most.champ\](.*)}]] 1 2]
					variable stat_best_finder [lrange [lindex $stats [lsearch -regexp $stats {^\[best.finder\](.*)}]] 1 2]
					variable stat_fastest_play [lrange [lindex $stats [lsearch -regexp $stats {^\[fastest.play\](.*)}]] 1 2]
					variable stat_total_rounds [lindex [lindex $stats [lsearch -regexp $stats {^\[total.rounds\](.*)}]] 1]
					# si un fichier player.stats existe déjà on le lit
					if {[file exists $::motus::playerstats_file]} {
						set fichierstats [open $::motus::playerstats_file r]
						set read_playerstats [split [read -nonewline $fichierstats] "\n"]
						close $fichierstats
						set make_player_stats 0
						# si l'entête du fichier lu est invalide, on le réécrit intégralement
						if {[::tcl::string::first !#v [set read_stats_header [join [lindex $read_playerstats 0]]]] != 0} { 
							putloglev o * "\00304\002\[Motus - erreur\]\002\003 le fichier de statistiques des joueurs est corrompu. Recréation d'un nouveau fichier."
							set make_player_stats 1
						}
						set stats_must_be_written 0
						# si l'entête du fichier players.stats est < à la v3.2, on le convertit ainsi que le fichier motus.scores
						if { [package vcompare [::tcl::string::range [lindex [split $read_stats_header ":"] 0] 3 end] 3.2] == -1 } {
							file copy -force -- $::motus::playerstats_file [set ::motus::playerstats_file].old
							file copy -force -- $::motus::stats_file [set ::motus::stats_file].old
							file copy -force -- $::motus::scores_file [set ::motus::scores_file].old
							set read_playerstats [lreplace [::tcl::string::map -nocase {"%!" "@1" "!%" "@2" "!@" "@3" "@!" "@4" ":!" "@5" "!:" "@6" "!;" "@7" ";!" "@8"} $read_playerstats] 0 0 "!#v$::motus::version:$::botnick"]
							set ::motus::stats [::tcl::string::map -nocase {"%!" "@1" "!%" "@2" "!@" "@3" "@!" "@4" ":!" "@5" "!:" "@6" "!;" "@7" ";!" "@8"} $::motus::stats]
							set ::motus::scores [::tcl::string::map -nocase {"%!" "@1" "!%" "@2" "!@" "@3" "@!" "@4" ":!" "@5" "!:" "@6" "!;" "@7" ";!" "@8"} $::motus::scores]
							::motus::ecrit_scores
							set stats_must_be_written 1
						}
					# sinon on en crée un
					} else {
						set stats_must_be_written 0
						set make_player_stats 1
					}
					if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug - module de statistiques\]\002\003 make_player_stats : \00314$make_player_stats\003 \00307|\003 read_playerstats : \00314$read_playerstats\003" }
					if {$make_player_stats} { set read_playerstats "!#v$::motus::version:$::botnick" }
					# transformation des statistiques des joueurs en array
					array set player_stats {}
					variable player_stats_header [lindex $read_playerstats 0]
					# counter commence à 1 car l'index 0 contient l'entête du fichier des statistiques des joueurs
					for { set counter 1 } { $counter <= [llength $read_playerstats] } { incr counter } {
						set player_entry [split [lindex $read_playerstats $counter] ","]
						if {[set player_name [::tcl::string::tolower [join [lindex $player_entry 0]]]] ne ""} { set player_stats($player_name) [lrange $player_entry 0 8] }
					}
					# S'il y a eu conversion des statistiques depuis une ancienne version, on doit les réécrire
					if { $stats_must_be_written } {
						::motus::stats do write.stats players - -
						::motus::stats do write.stats game - -
					}
					return
				}
				"write.stats" {
					switch -- $parameter1 {
						"game" {
							if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug - module de statistiques\]\002\003 écriture du fichier de statistiques du jeu" }
							if { ([::tcl::info::exists $::motus::stats_file]) && (![motus::is_writable $::motus::stats_file 1]) } { return }
							set fichierstats [open $::motus::stats_file w]
							puts $fichierstats [join $stats "\n"]
							close $fichierstats
						}
						"players" {
							if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug - module de statistiques\]\002\003 écriture du fichier de statistiques des joueurs" }
							set array_search_ID [array startsearch player_stats]
							while { [array anymore player_stats $array_search_ID] } {
								lappend output_player_stats [join $player_stats([array nextelement player_stats $array_search_ID]) ","]
							}
							array donesearch player_stats $array_search_ID
							if { [::tcl::info::exists output_player_stats] } { set output_player_stats [linsert [lsort -dict $output_player_stats] 0 $::motus::player_stats_header] }
							if { ([::tcl::info::exists $::motus::playerstats_file]) && (![motus::is_writable $::motus::playerstats_file 1]) } { return }
							set fichierstats [open $::motus::playerstats_file w]
							puts $fichierstats [join $output_player_stats "\n"]
							close $fichierstats
						}
					}
					return
				}
				"rename.player" {
					# $oldnick et $newnick sont supposés reçus sous la forme filtrée (motus::clean_nick) mais avec la casse d'origine
					#
					# si $nick a un score, on le transfère à $newnick et on note si un doublon est créé dans les scores.
					# Si un doublon existe, ses scores seront fusionnés dès qu'il aura fait au moins une proposition de
					# mot valide (c'est à dire un mot de la bonne longueur) après s'être renommé, et ce afin de limiter
					# les risques de vol de score.
					set oldnick [motus::restore_nick $parameter1]
					set newnick [motus::restore_nick $parameter2]
					if { [set scorepos [lsearch $::motus::scores "$parameter1 *"]] != -1 } {
						set playerscoreexists 1
						variable scores [lreplace $::motus::scores $scorepos $scorepos "$parameter2 [motus::score $oldnick]"]
						if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003 $oldnick \00314s'est renommé en\003 $newnick\00314. Scores :\003 $scores" }
						::motus::ecrit_scores
					}
					set lowernewnick [::tcl::string::tolower $parameter2]
					if { [::tcl::info::exists player_stats([set loweroldnick [::tcl::string::tolower $parameter1]])] } {
						if { [::tcl::info::exists playerscoreexists] } { puthelp "NOTICE $newnick :[code warning]\002\[Motus\]\002[code stop] J'ai remarqué ton changement de pseudo, ton score a été transféré." }
						# si $player_stats($lowernewnick) n'existe pas, on renomme simplement $player_stats($loweroldnick) en $player_stats($lowernewnick)
						if {![::tcl::info::exists player_stats($lowernewnick)]} {
							set player_stats($lowernewnick) "$parameter2 [lrange $player_stats($loweroldnick) 1 8]"
							unset player_stats($loweroldnick)
						# sinon, si $player_stats($lowernewnick) existe déjà ET que $player_stats($loweroldnick) existe, on les fusionne dans $player_stats($lowernewnick)
						} elseif { ([::tcl::info::exists player_stats($lowernewnick)]) && ([::tcl::info::exists player_stats($loweroldnick)]) && ($lowernewnick ne $loweroldnick) } {
							if { $::motus::warn_on_fusion } {
								::motus::putlog_split_line  "\00304\002\[Motus - info\]\002\003\00307 $oldnick\003\00314![getchanhost $newnick] ([nick2hand $newnick])\003 vient de changer de pseudo (\00307\002\002$oldnick\003 \
								-> \00307\002\002$newnick\003); une entrée existe déjà à ce nom dans les statistiques personnelles -> \
								on transfère ses stats et on opère les fusions nécessaires \00314([if {[::tcl::info::exists ::motus::player_stats($loweroldnick)]} \
								{set dummy $::motus::player_stats($loweroldnick)}] + [if {[::tcl::info::exists ::motus::player_stats($lowernewnick)]} {set dummy $::motus::player_stats($lowernewnick)}])\003"
							}
							for { set counter 1 } { $counter <= 7 } { incr counter } {
								lappend temp_values [expr [lindex $player_stats($loweroldnick) $counter] + [lindex $player_stats($lowernewnick) $counter]]
							}
							set quickness0 [lindex $player_stats($loweroldnick) 8]
							set quickness1 [lindex $player_stats($lowernewnick) 8]
							if { $quickness0 == 0 } { set quickness $quickness1 } elseif { $quickness1 == 0 } { set quickness $quickness0 } else { set quickness [expr ($quickness0 < $quickness1)?$quickness0:$quickness1] }
							set player_stats($lowernewnick) "[lindex $player_stats($lowernewnick) 0] $temp_values $quickness"
							unset player_stats($loweroldnick)
						}
					}
					# sinon, si $player_stats($loweroldnick) n'existe pas (si $loweroldnick n'a fait aucune proposition par exemple), on n'a besoin de toucher à rien.
					#
					# si $loweroldnick était champion de la semaine, alors on transfère le titre à $lowernewnick
					if {[::tcl::string::tolower [lindex $::motus::stat_week_champ 1]] eq $loweroldnick} {
						::motus::stats update record.week_champ $parameter2 [lindex $::motus::stat_week_champ 0] dontwrite
					}
					# si $loweroldnick détenait record.most_champ, alors on transfère le titre à $lowernewnick
					if {[::tcl::string::tolower [lindex $::motus::stat_most_champ 1]] eq $loweroldnick} {
						::motus::stats update record.most_champ $parameter2 [lindex $::motus::stat_most_champ 0] dontwrite
					}
					# si $oldnick détenait record.best_finder OU si des entrées ont été fusionnées,
					# on réévalue record.best_finder (car les valeurs de player.finder_count peuvent
					# avoir augmenté)
					if { ( [::tcl::info::exists player_stats($lowernewnick)] ) && (( [set player_nb_rounds [lindex $player_stats($lowernewnick) 1]] >= [lindex $::motus::stat_best_finder 0] ) || ( $loweroldnick eq [::tcl::string::tolower [lindex $::motus::stat_best_finder 1]] )) } {
						variable stat_best_finder [list [lindex $player_stats($lowernewnick) 1] [lindex $player_stats($lowernewnick) 0]]
						variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[best.finder\](.*)}]] $index "\[best.finder\] $::motus::stat_best_finder"]
					}
					if { $write_file eq "write" } {
						::motus::stats do write.stats game - -
						::motus::stats do write.stats players - -
					}
				}
				"week.change" {
					# Si le jour actuel n'est pas le jour qu'on a programmé pour le roulement des statistiques, on ne va pas plus loin
					# (vérification nécessaire car le bind time ne peut pas être exécuté en fonction du jour de la semaine,
					# il est donc exécuté chaque jour à $::motus::clearscores_time heures)
					if { [lindex [ctime [unixtime]] 0] != [::tcl::string::map -nocase {lundi Mon mardi Tue mercredi Wed jeudi Thu vendredi Fri samedi Sat dimanche Sun} $::motus::clearscores_day] } { return }
					set current_time [split [lindex [ctime [unixtime]] 3] ":"]
					if { [channel get $::motus::motus_chan motus] == 1 } { puthelp "PRIVMSG $::motus::motus_chan :[code warning]\002Nous sommes $::motus::clearscores_day et il est [lindex $current_time 0]h[lindex $current_time 1]; une nouvelle semaine commence pour les statistiques du Motus." }
					# nouvelle semaine de stats : le champion de la semaine devient le champion de la semaine dernière
					variable stat_last_week_champ $::motus::stat_week_champ
					variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[last.week.champ\](.*)}]] $index "\[last.week.champ\] $::motus::stat_last_week_champ"]
					# le champion de la semaine qui commence est réinitialisé
					::motus::stats update record.week_champ personne 0 dontwrite
					# Le champion de la semaine dernière a gagné un titre de champion
					# (il est vérifié au passage si c'est lui qui détient le plus de titres de champion
					# et stat_most_champ est mis à jour si nécessaire)
					lassign $::motus::stat_last_week_champ last_champ_score last_champ_name
					if { $last_champ_score != 0 } {
						::motus::stats update player.champ_count $last_champ_name 1 dontwrite
						if { $::motus::achievements_enabled } { ::motus::announce_achievements champ_titles $last_champ_name [lindex $::motus::player_stats([::tcl::string::tolower $last_champ_name]) 2] }
					}
					# on met à jour le top3 des meilleurs champions si nécessaire
					::motus::stats update record.all_time_top3 [lindex $::motus::stat_last_week_champ 1] $last_champ_score dontwrite
					# on écrit les fichiers de statistiques
					::motus::stats do write.stats game - -
					::motus::stats do write.stats players - -
					return
				}
				"reset" {
					file delete -force -- $::motus::stats_file
					file delete -force -- $::motus::playerstats_file
					# les 2 fichiers suivants n'existent plus à partir de la version 2.2 du Motus
					# mais on les efface quand même au cas où ils sont présent (en cas de reset des
					# stats juste après une mise à jour depuis une ancienne version par exemple)
					file delete -force -- $::motus::champ_file
					file delete -force -- $::motus::finder_file
					# on demande une lecture des stats (ce qui va forcer au passage
					# la recréation des fichiers qu'on vient d'effacer)
					::motus::stats do read.stats - - -
					puthelp "PRIVMSG $::motus::motus_chan :[code warning]\002Les statistiques du Motus ont été remises à zéro à la demande de $parameter1."
					return
				}
			}
		}
		"update" {
			switch -- $subcommand {
				"player.finder_count" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					# si une entrée existe déjà, on la met à jour
					if { [::tcl::info::exists player_stats($nick)] } {
						set player_stats($nick) [lreplace $player_stats($nick) 1 1 [expr [lindex $player_stats($nick) 1] + $parameter2]]
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] $parameter2 0 0 0 0 0 0 0]
					}
					if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
					# on actualise record.best_finder si nécessaire
					::motus::stats update record.best_finder $nick [lindex $player_stats($nick) 1] $write_file
					return
				}
				"player.champ_count" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					# si une entrée existe déjà, on la met à jour
					if { [::tcl::info::exists player_stats($nick)] } {
						set player_stats($nick) [lreplace $player_stats($nick) 2 2 [expr [lindex $player_stats($nick) 2] + $parameter2]]
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] 0 $parameter2 0 0 0 0 0 0]
					}
					if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
					# on actualise record.most_champ si nécessaire
					::motus::stats update record.most_champ $nick [lindex $player_stats($nick) 2] $write_file
					return
				}
				"player.global_score" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					# si une entrée existe déjà, on la met à jour
					if { [::tcl::info::exists player_stats($nick)] } {
						set player_stats($nick) [lreplace $player_stats($nick) 3 3 [expr [lindex $player_stats($nick) 3] + $parameter2]]
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] 0 0 $parameter2 0 0 0 0 0]
					}
					if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
					return
				}
				"player.total_words" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					# si une entrée existe déjà, on la met à jour
					if { [::tcl::info::exists player_stats($nick)] } {
						set player_stats($nick) [lreplace $player_stats($nick) 4 4 [expr [lindex $player_stats($nick) 4] + $parameter2]]
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] 0 0 0 $parameter2 0 0 0 0]
					}
					if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
					return
				}
				"player.failures" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					# si une entrée existe déjà, on la met à jour
					if { [::tcl::info::exists player_stats($nick)] } {
						set player_stats($nick) [lreplace $player_stats($nick) 5 5 [expr [lindex $player_stats($nick) 5] + $parameter2]]
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] 0 0 0 0 $parameter2 0 0 0]
					}
					if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
					return
				}
				"player.valid_letters" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					# si une entrée existe déjà, on la met à jour
					if { [::tcl::info::exists player_stats($nick)] } {
						set player_stats($nick) [lreplace $player_stats($nick) 6 6 [expr [lindex $player_stats($nick) 6] + $parameter2]]
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] 0 0 0 0 0 $parameter2 0 0]
					}
					if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
					return
				}
				"player.misplaced_letters" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					# si une entrée existe déjà, on la met à jour
					if { [::tcl::info::exists player_stats($nick)] } {
						set player_stats($nick) [lreplace $player_stats($nick) 7 7 [expr [lindex $player_stats($nick) 7] + $parameter2]]
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] 0 0 0 0 0 0 $parameter2 0]
					}
					if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
					return
				}
				"player.best_time" {
					set nick [::tcl::string::tolower [motus::clean_nick $parameter1]]
					set check_record 0
					# si une entrée existe déjà, on la met à jour si nécessaire
					if { [::tcl::info::exists player_stats($nick)] } {
						if { ($parameter2 < [set player_previous_time [lindex $player_stats($nick) 8]]) || ($player_previous_time == 0) } {
							if { $player_previous_time != 0 } { ::motus::putqueue "PRIVMSG $::motus::motus_chan :[code 5,1]i![code stop][code 7,1]i![code stop][code 8,1]i![code stop][code 0,1]i! [code stop][code 7,1]\002RECORD PERSONNEL BATTU\002[code stop][code 0,1] !i[code stop][code 8,1]!i[code stop][code 7,1]!i[code stop][code 5,1]!i[code stop] [code announce_special]\002[motus::restore_nick [lindex $player_stats($nick) 0]]\002[code stop][code announce] vient de battre son record personnel de rapidité en l'améliorant de [code stop][code announce_special]\002[format "%.2f" [expr $player_previous_time - $parameter2]]\002[code stop][code announce] secondes. Son meilleur temps précédent était de [code stop][code announce_special]\002$player_previous_time\002[code stop][code announce] secondes.[code stop]" }
							set player_stats($nick) [lreplace $player_stats($nick) 8 8 $parameter2]
							if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
							set check_record 1
						}
					# sinon on en crée une
					} else {
						set player_stats($nick) [list [motus::clean_nick $parameter1] 0 0 0 0 0 0 0 $parameter2]
						if { $write_file eq "write" } { ::motus::stats do write.stats players - - }
						set check_record 1
					}
					# on actualise record.fastest_play si nécessaire
					if { $check_record } { ::motus::stats update record.fastest_play $nick [lindex $player_stats($nick) 8] $write_file }
					return
				}
				"record.best_finder" {
					if { $parameter2 > [lindex $::motus::stat_best_finder 0] } {
						if {($parameter1 ne [::tcl::string::tolower [set stat_best_finder_name [lindex $::motus::stat_best_finder 1]]]) && ($stat_best_finder_name ne "personne")} {
							::motus::putqueue "PRIVMSG $::motus::motus_chan :[code 5,1]i![code stop][code 7,1]i![code stop][code 8,1]i![code stop][code 0,1]i! [code stop][code 4,1]\002RECORD BATTU\002[code stop][code 0,1] !i[code stop][code 8,1]!i[code stop][code 7,1]!i[code stop][code 5,1]!i[code stop] [code announce_special]\002[motus::restore_nick [lindex $player_stats($parameter1) 0]]\002[code stop][code announce] vient juste de battre le record du plus grand nombre de bonnes propositions avec [code stop][code announce_special]\002$parameter2\002[code stop][code announce] Motus trouvés. Le précédent détenteur du record était [code stop][code announce_special]\002[motus::restore_nick $stat_best_finder_name]\002[code stop][code announce].[code stop]"
						}
						variable stat_best_finder [list [lindex $player_stats($parameter1) 1] [lindex $player_stats($parameter1) 0]]
						variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[best.finder\](.*)}]] $index "\[best.finder\] $::motus::stat_best_finder"]
						if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					}
					return
				}
				"record.most_champ" {
					if { $parameter2 > [lindex $::motus::stat_most_champ 0] } {
						if {($parameter1 ne [::tcl::string::tolower [set stat_most_champ_name [lindex $::motus::stat_most_champ 1]]]) && ($stat_most_champ_name ne "personne")} {
							::motus::putqueue "PRIVMSG $::motus::motus_chan :[code 5,1]i![code stop][code 7,1]i![code stop][code 8,1]i![code stop][code 0,1]i! [code stop][code 4,1]\002RECORD BATTU\002[code stop][code 0,1] !i[code stop][code 8,1]!i[code stop][code 7,1]!i[code stop][code 5,1]!i[code stop] [code announce_special]\002[motus::restore_nick [lindex $player_stats($parameter1) 0]]\002[code stop][code announce] vient juste de battre le record du plus grand nombre de titres de champion de la semaine avec [code stop][code announce_special]\002$parameter2\002[code stop][code announce] titres. Le précédent détenteur du record était [code stop][code announce_special]\002[motus::restore_nick $stat_most_champ_name]\002[code stop][code announce].[code stop]"
						}
						variable stat_most_champ [list [lindex $player_stats($parameter1) 2] [lindex $player_stats($parameter1) 0]]
						variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[most.champ\](.*)}]] $index "\[most.champ\] $::motus::stat_most_champ"]
						if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					}
					return
				}
				"record.fastest_play" {
					if { ($parameter2 < [set stat_fastest_play_score [lindex $::motus::stat_fastest_play 0]]) || ($stat_fastest_play_score == 0) } {
						if {($parameter1 ne [::tcl::string::tolower [set stat_fastest_play_name [lindex $::motus::stat_fastest_play 1]]]) && ($stat_fastest_play_name ne "personne")} {
							::motus::putqueue "PRIVMSG $::motus::motus_chan :[code 5,1]i![code stop][code 7,1]i![code stop][code 8,1]i![code stop][code 0,1]i! [code stop][code 4,1]\002RECORD BATTU\002[code stop][code 0,1] !i[code stop][code 8,1]!i[code stop][code 7,1]!i[code stop][code 5,1]!i[code stop] [code announce_special]\002[motus::restore_nick [lindex $player_stats($parameter1) 0]]\002[code stop][code announce] vient de battre le record de rapidité au Motus en l'améliorant de [code stop][code announce_special]\002[format "%.2f" [expr $stat_fastest_play_score - $parameter2]]\002[code stop][code announce] secondes. Il était précédemment détenu par [code stop][code announce_special]\002[motus::restore_nick $stat_fastest_play_name]\002[code stop][code announce] qui avait trouvé un mot en [code stop][code announce_special]\002$stat_fastest_play_score\002[code stop][code announce] secondes.[code stop]"
						}
						variable stat_fastest_play [list [lindex $player_stats($parameter1) 8] [lindex $player_stats($parameter1) 0]]
						variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[fastest.play\](.*)}]] $index "\[fastest.play\] $::motus::stat_fastest_play"]
						if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					}
					return
				}
				"record.week_champ" {
					# $parameter1 (le nick) est reçu sous la forme clean_nick
					# si les paramètres sont "personne" et "0", il s'agit d'une réinitialisation de stat_week_champ
					if { ($parameter1 eq "personne") && ($parameter2 == 0) } {
						variable stat_week_champ "0 personne"
						variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[week.champ\](.*)}]] $index "\[week.champ\] $::motus::stat_week_champ"]
						if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
						return
					}
					set nick [::tcl::string::tolower $parameter1]
					# si le score de $nick est supérieur au score du champion de la semaine, il prend sa place
					if { $parameter2 > [set stat_week_champ_score [lindex $::motus::stat_week_champ 0]] } {
						if {($nick ne [::tcl::string::tolower [set stat_week_champ_name [lindex $::motus::stat_week_champ 1]]]) && ($stat_week_champ_name ne "personne") && !(([::tcl::info::exists ::motus::nickchange_array($parameter1)]) && ($::motus::nickchange_array($parameter1) ne $stat_week_champ_name))} {
							::motus::putqueue "PRIVMSG $::motus::motus_chan :[code announce_special]\002[motus::restore_nick $stat_week_champ_name]\002[code announce] ([code announce_special]\002[lindex $::motus::stat_week_champ 0]\002[code announce]pts) vient juste de perdre sa place de champion de la semaine. Tu es en tête [code announce_special]\002[motus::restore_nick [lindex $player_stats($nick) 0]]\002[code announce] !"
						}
						variable stat_week_champ [list $parameter2 [lindex $player_stats($nick) 0]]
						variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[week.champ\](.*)}]] $index "\[week.champ\] $::motus::stat_week_champ"]
						if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					# si le score de $nick est inférieur au score du champion de la semaine ET QUE $nick EST le champion de la semaine, il perd sa place
					} elseif { ($parameter2 < $stat_week_champ_score ) && ($nick eq [::tcl::string::tolower [lindex $::motus::stat_week_champ 1]]) } {
						# si le nick de la 1ère place dans les scores n'est plus $nick, on signale que $nick a perdu sa place
						if { $nick ne [::tcl::string::tolower [set new_week_champ_name [lindex [set first_place [lindex $::motus::scores 0]] 0]]] } {
							::motus::putqueue "PRIVMSG $::motus::motus_chan :[code announce_special]\002[motus::restore_nick [lindex $player_stats($nick) 0]]\002[code announce] vient juste de perdre sa place de champion de la semaine. [code announce_special]\002[motus::restore_nick $new_week_champ_name]\002[code announce] ([code announce_special]\002[lindex $first_place 1]\002[code announce]pts) a repris le titre."
						}
						variable stat_week_champ "[list [lindex $first_place 1] $new_week_champ_name]"
						variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[week.champ\](.*)}]] $index "\[week.champ\] $::motus::stat_week_champ"]
						if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					}
					return
				}
				"record.all_time_top3" {
					lappend ::motus::stat_all_time_top3 "$parameter1 $parameter2"
					variable stat_all_time_top3 [lrange [lsort -integer -index 1 -decreasing $::motus::stat_all_time_top3] 0 2]
					variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[all.time.top3\](.*)}]] $index "\[all.time.top3\] $::motus::stat_all_time_top3"]
					if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					return
				}
				"stat.last_scores_reset" {
					variable stat_last_scores_reset $parameter1
					variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[last.scores.reset\](.*)}]] $index "\[last.scores.reset\] $::motus::stat_last_scores_reset"]
					if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					return
				}
				"stat.total_rounds" {
					incr ::motus::stat_total_rounds $parameter1
					variable stats [lreplace $stats [set index [lsearch -regexp $stats {^\[total.rounds\](.*)}]] $index "\[total.rounds\] $::motus::stat_total_rounds"]
					if { $write_file eq "write" } { ::motus::stats do write.stats game - - }
					return
				}
			}
		}
	}
}

##### Remise à 0 des statistiques (pas les scores)
proc ::motus::reset_stats {nick host hand chan arg} {
	if {![channel get $::motus::motus_chan motus]} { return }
	::motus::backup_files 0 0 0 0 0
	::motus::stats do reset $nick - -
	return
}

##### Changement de semaine (roulement des statistiques)
proc ::motus::stats_week_change {min hour day month year} {
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	::motus::stats do week.change - - -
	return
}

##### Annonce des hauts faits
proc ::motus::announce_achievements {type nick value} {
	# $nick doit être reçu sous la forme clean_nick
	# $type peut valoir rounds_won champ_titles total_score total_words best_time bonus
	variable achievement_header "[code 5,1]i![code stop][code 7,1]i![code stop][code 8,1]i![code stop][code 0,1]i! [code stop][code 7,1]\002HAUT FAIT ACCOMPLI\002[code stop][code 0,1] !i[code stop][code 8,1]!i[code stop][code 7,1]!i[code stop][code 5,1]!i[code stop]"
	set rounds_won_magic_list {10 50 100 200 500 1000 2000 5000 10000 20000 50000 100000 200000 500000 1000000}
	set champ_titles_magic_list {1 5 10 20 50 100}
	set total_score_magic_list {1000 5000 10000 20000 50000 100000 200000 500000 1000000 2000000 5000000 10000000 20000000 50000000 100000000}
	set total_words_magic_list {1000 2000 5000 10000 20000 50000 100000 200000 500000 1000000 2000000 5000000 10000000}
	# best_time : < 30 | < 10 | < 5 | < 3 | < 2
	# bonus : catégorie 1 complète | catégorie 2 complète | catégorie 3 complète | catégorie 4 complète | catégorie 5 complète | toutes catégories complètes
	set lowernick [::tcl::string::tolower $nick]
	switch -- $type {
		"rounds_won" {
			if { [lsearch $rounds_won_magic_list $value] != -1 } {
				set category_completed 0
				switch $value {
					"10" { set value "dixième" ; set points 1 }
					"50" { set value "cinquantième" ; set points 1 }
					"100" { set value "centième" ; set points 1 }
					"200" { set value "200ème" ; set points 1 }
					"500" { set value "500ème" ; set points 1 }
					"1000" { set value "millième" ; set points 2 }
					"2000" { set value "2 000ème" ; set points 2 }
					"5000" { set value "5 000ème" ; set points 2 }
					"10000" { set value "10 000ème" ; set points 3 }
					"20000" { set value "20 000ème" ; set points 3 }
					"50000" { set value "50 000ème" ; set points 3 }
					"100000" { set value "100 000ème" ; set points 4 }
					"200000" { set value "200 000ème" ; set points 4 }
					"500000" { set value "500 000ème" ; set points 4 }
					"1000000" { set value "millionième" ; set points 5 ; set category_completed 1 }
				}
				::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] vient de remporter son [code stop][code announce_special]\002[set value]\002[code stop][code announce] round, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
				if { $category_completed } {
					set points 8
					::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] a accompli tous les hauts faits de la catégorie \002nombre de rounds gagnés\002, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
					::motus::check_for_all_achievements_accomplished $nick $lowernick
				}
			}
		}
		"champ_titles" {
			if { [lsearch $champ_titles_magic_list $value] != -1 } {
				set category_completed 0
				switch $value {
					"1" { set value "premier" ; set points 1 }
					"5" { set value "cinquième" ; set points 2 }
					"10" { set value "dixième" ; set points 3 }
					"20" { set value "vingtième" ; set points 4 }
					"50" { set value "cinquantième" ; set points 5 }
					"100" { set value "centième" ; set points 6 ; set category_completed 1 }
				}
				::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] vient de remporter son [code stop][code announce_special]\002[set value]\002[code stop][code announce] titre de champion, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
				if { $category_completed } {
					set points 8
					::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] a accompli tous les hauts faits de la catégorie \002nombre de titres de champion\002, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
					::motus::check_for_all_achievements_accomplished $nick $lowernick
				}
			}
		}
		"total_score" {
			if { [lsearch $total_score_magic_list $value] != -1 } {
				set category_completed 0
				switch $value {
					"1000" { set value "1 000" ; set points 1 }
					"5000" { set value "5 000" ; set points 1 }
					"10000" { set value "10 000" ; set points 1 }
					"20000" { set value "20 000" ; set points 1 }
					"50000" { set value "50 000" ; set points 1 }
					"100000" { set value "100 000" ; set points 2 }
					"200000" { set value "200 000" ; set points 2 }
					"500000" { set value "500 000" ; set points 2 }
					"1000000" { set value "1 000 000" ; set points 3 }
					"2000000" { set value "2 000 000" ; set points 3 }
					"5000000" { set value "5 000 000" ; set points 3 }
					"10000000" { set value "10 000 000" ; set points 4 }
					"20000000" { set value "20 000 000" ; set points 4 }
					"50000000" { set value "50 000 000" ; set points 4 }
					"100000000" { set value "100 000 000" ; set points 5 ; set category_completed 1 }
				}
				::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] vient d'atteindre un score cumulé de [code stop][code announce_special]\002[set value]\002[code stop][code announce] points, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
				if { $category_completed } {
					set points 8
					::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] a accompli tous les hauts faits de la catégorie \002score cumulé\002, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
					::motus::check_for_all_achievements_accomplished $nick $lowernick
				}
			}
		}
		"total_words" {
			if { [lsearch $total_words_magic_list $value] != -1 } {
				set category_completed 0
				switch $value {
					"1000" { set value "millième" ; set points 1 }
					"2000" { set value "2 000ème" ; set points 1 }
					"5000" { set value "5 000ème" ; set points 1 }
					"10000" { set value "10 000ème" ; set points 2 }
					"20000" { set value "20 000ème" ; set points 2 }
					"50000" { set value "50 000ème" ; set points 2 }
					"100000" { set value "100 000ème" ; set points 3 }
					"200000" { set value "200 000ème" ; set points 3 }
					"500000" { set value "500 000ème" ; set points 3 }
					"1000000" { set value "millionième" ; set points 4 }
					"2000000" { set value "2 000 000ème" ; set points 4 }
					"5000000" { set value "5 000 000ème" ; set points 4 }
					"10000000" { set value "10 000 000ème" ; set points 5 ; set category_completed 1 }
				}
				::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] vient de proposer son [code stop][code announce_special]\002[set value]\002[code stop][code announce] mot, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
				if { $category_completed } {
					set points 8
					::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] a accompli tous les hauts faits de la catégorie \002nombre de mots proposés\002, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
					::motus::check_for_all_achievements_accomplished $nick $lowernick
				}
			}
		}
		"best_time" {
			set has_something_to_say 1
			set category_completed 0
			if { $value < 2 } {
				set value "2" ; set points 5 ; set category_completed 1
			} elseif { $value < 3 } {
				set value "3" ; set points 3
			} elseif { $value < 5 } {
				set value "5" ; set points 2
			} elseif { $value < 10 } {
				set value "10" ; set points 1
			} elseif { $value < 30 } {
				set value "30" ; set points 1
			} else {
				set has_something_to_say 0
			}
			if { $has_something_to_say } {
				::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] vient de trouver un mot en moins de [code stop][code announce_special]\002[set value]\002[code stop][code announce] secondes, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
				if { $category_completed } {
					set points 8
					::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] a accompli tous les hauts faits de la catégorie \002meilleur temps\002, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
					::motus::check_for_all_achievements_accomplished $nick $lowernick
				}
			}
		}
	}
}

##### Si tous les hauts faits ont été accomplis, on l'annonce
proc ::motus::check_for_all_achievements_accomplished {nick lowernick} {
	if { [lindex $::motus::player_stats($lowernick) 1] >= 1000000
		&& [lindex $::motus::player_stats($lowernick) 2] >= 100
		&& [lindex $::motus::player_stats($lowernick) 3] >= 100000000
		&& [lindex $::motus::player_stats($lowernick) 4] >= 10000000
		&& [lindex $::motus::player_stats($lowernick) 8] < 2
	} then {
		::motus::putqueue "PRIVMSG $::motus::motus_chan :$::motus::achievement_header [code announce_special]\002[motus::restore_nick $nick]\002[code stop][code announce] a accompli tous les hauts faits du jeu, ce qui lui fait gagner [code stop][code announce_special]\002$points\002[code stop][code announce] point[motus::plural $points] de hauts faits pour un total de [code stop][code announce_special]\002[motus::achievements_points $lowernick]/$::motus::max_achievements_points\002[code stop][code announce].[code stop]"
	}
}

##### Calcul des points de hauts faits
proc ::motus::achievements_points {nick} {
	# $nick doit être reçu sous la forme "string tolower clean_nick"
	if {![::tcl::info::exists ::motus::player_stats($nick)]} { return 0 }
	set points 0
	set rounds_won_category_finished 0
	set champ_titles_category_finished 0
	set total_score_category_finished 0
	set total_words_category_finished 0
	set best_time_category_finished 0
	set all_categories_finished 0
	# rounds_won ( 10 | 50 | 100 | 200 | 500 | 1 000 | 2 000 | 5 000 | 10 000 | 20 000 | 50 000 | 100 000 | 200 000 | 500 000 | 1 000 000 )
	set rounds_won [lindex $::motus::player_stats($nick) 1]
	if { $rounds_won >= 1000000 } {
		incr points 37
		set rounds_won_category_finished 1
	} elseif { $rounds_won >= 500000 } {
		incr points 32
	} elseif { $rounds_won >= 200000 } {
		incr points 28
	} elseif { $rounds_won >= 100000 } {
		incr points 24
	} elseif { $rounds_won >= 50000 } {
		incr points 20
	} elseif { $rounds_won >= 20000 } {
		incr points 17
	} elseif { $rounds_won >= 10000 } {
		incr points 14
	} elseif { $rounds_won >= 5000 } {
		incr points 11
	} elseif { $rounds_won >= 2000 } {
		incr points 9
	} elseif { $rounds_won >= 1000 } {
		incr points 7
	} elseif { $rounds_won >= 500 } {
		incr points 5
	} elseif { $rounds_won >= 200 } {
		incr points 4
	} elseif { $rounds_won >= 100 } {
		incr points 3
	} elseif { $rounds_won >= 50 } {
		incr points 2
	} elseif { $rounds_won >= 10 } {
		incr points 1
	}
	# champ_titles ( 1 | 5 | 10 | 20 | 50 | 100 )
	set champ_titles [lindex $::motus::player_stats($nick) 2]
	if { $champ_titles >= 100 } {
		incr points 21
		set champ_titles_category_finished 1
	} elseif { $champ_titles >= 50 } {
		incr points 15
	} elseif { $champ_titles >= 20 } {
		incr points 10
	} elseif { $champ_titles >= 10 } {
		incr points 6
	} elseif { $champ_titles >= 5 } {
		incr points 3
	} elseif { $champ_titles >= 1 } {
		incr points 1
	}
	# total_score ( 1 000 | 5 000 | 10 000 | 20 000 | 50 000 | 100 000 | 200 000 | 500 000 | 1 000 000 | 2 000 000 | 5 000 000 | 10 000 000 | 20 000 000 | 50 000 000 | 100 000 000 )
	set total_score [lindex $::motus::player_stats($nick) 3]
	if { $total_score >= 100000000 } {
		incr points 37
		set total_score_category_finished 1
	} elseif { $total_score >= 50000000 } {
		incr points 32
	} elseif { $total_score >= 20000000 } {
		incr points 28
	} elseif { $total_score >= 10000000 } {
		incr points 24
	} elseif { $total_score >= 5000000 } {
		incr points 20
	} elseif { $total_score >= 2000000 } {
		incr points 17
	} elseif { $total_score >= 1000000 } {
		incr points 14
	} elseif { $total_score >= 500000 } {
		incr points 11
	} elseif { $total_score >= 200000 } {
		incr points 9
	} elseif { $total_score >= 100000 } {
		incr points 7
	} elseif { $total_score >= 50000 } {
		incr points 5
	} elseif { $total_score >= 20000 } {
		incr points 4
	} elseif { $total_score >= 10000 } {
		incr points 3
	} elseif { $total_score >= 5000 } {
		incr points 2
	} elseif { $total_score >= 1000 } {
		incr points 1
	}
	# total_words ( 1 000 | 2 000 | 5 000 | 10 000 | 20 000 | 50 000 | 100 000 | 200 000 | 500 000 | 1 000 000 | 2 000 000 | 5 000 000 | 10 000 000 )
	set total_words [lindex $::motus::player_stats($nick) 4]
	if { $total_words >= 10000000 } {
		incr points 35
		set total_words_category_finished 1
	} elseif { $total_words >= 5000000 } {
		incr points 30
	} elseif { $total_words >= 2000000 } {
		incr points 26
	} elseif { $total_words >= 1000000 } {
		incr points 22
	} elseif { $total_words >= 500000 } {
		incr points 18
	} elseif { $total_words >= 200000 } {
		incr points 15
	} elseif { $total_words >= 100000 } {
		incr points 12
	} elseif { $total_words >= 50000 } {
		incr points 9
	} elseif { $total_words >= 20000 } {
		incr points 7
	} elseif { $total_words >= 10000 } {
		incr points 5
	} elseif { $total_words >= 5000 } {
		incr points 3
	} elseif { $total_words >= 2000 } {
		incr points 2
	} elseif { $total_words >= 1000 } {
		incr points 1
	}
	# best_time ( < 30 | < 10 | < 5 | < 3 | < 2 )
	set best_time [lindex $::motus::player_stats($nick) 8]
	if { $best_time < 2 } {
		incr points 12
		set best_time_category_finished 1
	} elseif { $best_time < 3 } {
		incr points 7
	} elseif { $best_time < 5 } {
		incr points 4
	} elseif { $best_time < 10 } {
		incr points 2
	} elseif { $best_time < 30 } {
		incr points 1
	}
	# bonus : catégorie 1 complète | catégorie 2 complète | catégorie 3 complète | catégorie 4 complète | catégorie 5 complète | toutes catégories complètes
	set num_finished_categories 0
	if { $rounds_won_category_finished } {
		incr points 8
		incr num_finished_categories 1
	}
	if { $champ_titles_category_finished } {
		incr points 8
		incr num_finished_categories 1
	}
	if { $total_score_category_finished } {
		incr points 8
		incr num_finished_categories 1
	}
	if { $total_words_category_finished } {
		incr points 8
		incr num_finished_categories 1
	}
	if { $best_time_category_finished } {
		incr points 8
		incr num_finished_categories 1
	}
	# toutes les catégories de hauts faits ont été accomplies
	if { $num_finished_categories == 5 } {
		incr points 18
	}
	return $points
}

##### Exportation HTML manuelle
proc ::motus::manual_html_export {nick host hand chan args} {
	if {![channel get $::motus::motus_chan motus]} { return }
	if {![file exists $::motus::stats_file]} {
		puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Il est impossible de générer de la page HTML car aucune statistique n'existe à ce jour.[code stop]"
		return
	}
	::motus::html_export "manual"
	puthelp "PRIVMSG $::motus::motus_chan :[code normaltext]Exportation des statistiques en HTML effectuée.[code stop]"
}
	
##### Exportation HTML
proc ::motus::html_export {arg} {
	if {$::motus::DEBUGMODE} { putlog "\00304\[Motus - debug]\003 Exportation HTML des statistiques / scores" }
	if {![file exists $::motus::stats_file]} {
		putloglev o * "\00304\002\[Motus - info\]\002\003 La génération automatique de la page de statistiques en HTML a échoué car aucune statistique n'existe à ce jour."
		return
	}
	# lecture du fichier index.html et initialisation des variables
	set fichiertemplate [open "$::motus::html_template_path/index.html" r]
	set read_template [read $fichiertemplate]
	close $fichiertemplate
	::motus::convert_player_stats_to_v2_2_if_needed
	::motus::stats do read.stats - - -
	# substitution des variables
	regsub -all -nocase {%CSS_FILENAME%} $read_template $::motus::css_filename read_template
	regsub -all -nocase {%SERVER%} $read_template $::network read_template
	regsub -all -nocase {%CHAN%} $read_template $::motus::motus_chan read_template
	regsub -all -nocase {%BOT%} $read_template $::botnick read_template
	regsub -all -nocase {%UPDATE.DATE%} $read_template [strftime "%d/%m/%Y" [unixtime]] read_template
	regsub -all -nocase {%UPDATE.TIME%} $read_template [strftime "%Hh%M" [unixtime]] read_template
	regsub -all -nocase {%MIN.WORD.LENGTH%} $read_template $::motus::min_word_length read_template
	regsub -all -nocase {%MAX.WORD.LENGTH%} $read_template $::motus::max_word_length read_template
	if {![::tcl::info::exists ::motus::totalmots]} { ::motus::charge_listemots ; unset ::motus::listemots }
	regsub -all -nocase {%TOTAL.WORDS%} $read_template $::motus::totalmots read_template
	regsub -all -nocase {%TOTAL.ODS%} $read_template 385574 read_template
	regsub -all -nocase {%LAST.SCORES.RESET.DATE%} $read_template [strftime "%d/%m/%Y" $::motus::stat_last_scores_reset] read_template
	regsub -all -nocase {%LAST.SCORES.RESET.TIME%} $read_template [strftime "%Hh%M" $::motus::stat_last_scores_reset] read_template
	for { set counter 1 } { $counter <= 10 } { incr counter } {
		regsub -all -nocase "%NICK$counter%" $read_template [motus::restore_nick [lindex [motus::score_pos $counter] 0]] read_template
		regsub -all -nocase "%SCORE$counter%" $read_template [lindex [motus::score_pos $counter] 1] read_template
	}
	regsub -all -nocase {%REFERENCE.TIME.DATE%} $read_template [strftime "%d/%m/%Y" $::motus::stat_reference_time] read_template
	regsub -all -nocase {%REFERENCE.TIME.TIME%} $read_template [strftime "%Hh%M" $::motus::stat_reference_time] read_template
	regsub -all -nocase {%TOTAL.ROUNDS%} $read_template $::motus::stat_total_rounds read_template
	regsub -all -nocase {%WEEK.CHAMP.NAME%} $read_template [motus::restore_nick [lindex $::motus::stat_week_champ 1]] read_template
	regsub -all -nocase {%WEEK.CHAMP.SCORE%} $read_template [lindex $::motus::stat_week_champ 0] read_template
	regsub -all -nocase {%LAST.WEEK.CHAMP.NAME%} $read_template [motus::restore_nick [lindex $::motus::stat_last_week_champ 1]] read_template
	regsub -all -nocase {%LAST.WEEK.CHAMP.SCORE%} $read_template [lindex $::motus::stat_last_week_champ 0] read_template
	regsub -all -nocase {%ALL.TIME.TOP3.1.NAME%} $read_template [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 0] 0]] read_template
	regsub -all -nocase {%ALL.TIME.TOP3.1.SCORE%} $read_template [lindex [lindex $::motus::stat_all_time_top3 0] 1] read_template
	regsub -all -nocase {%ALL.TIME.TOP3.2.NAME%} $read_template [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 1] 0]] read_template
	regsub -all -nocase {%ALL.TIME.TOP3.2.SCORE%} $read_template [lindex [lindex $::motus::stat_all_time_top3 1] 1] read_template
	regsub -all -nocase {%ALL.TIME.TOP3.3.NAME%} $read_template [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 2] 0]] read_template
	regsub -all -nocase {%ALL.TIME.TOP3.3.SCORE%} $read_template [lindex [lindex $::motus::stat_all_time_top3 2] 1] read_template
	regsub -all -nocase {%MOST.CHAMP.NAME%} $read_template [motus::restore_nick [lindex $::motus::stat_most_champ 1]] read_template
	regsub -all -nocase {%MOST.CHAMP.SCORE%} $read_template [lindex $::motus::stat_most_champ 0] read_template
	regsub -all -nocase {%BEST.FINDER.NAME%} $read_template [motus::restore_nick [lindex $::motus::stat_best_finder 1]] read_template
	regsub -all -nocase {%BEST.FINDER.SCORE%} $read_template [lindex $::motus::stat_best_finder 0] read_template
	regsub -all -nocase {%FASTEST.PLAY.NAME%} $read_template [motus::restore_nick [lindex $::motus::stat_fastest_play 1]] read_template
	regsub -all -nocase {%FASTEST.PLAY.SCORE%} $read_template [lindex $::motus::stat_fastest_play 0] read_template
	# Graphique d'activité
	#
	# s'il existe des archives des scores des périodes précédentes...
	if {[file exists $::motus::scores_archive_file]} {
		set fichierscoresarchive [open "$::motus::scores_archive_file" r]
		set read_scores_archive [regsub -all {[\}\{\[\]\(\)\\]} [read $fichierscoresarchive] {\\&}]
		close $fichierscoresarchive
		array set activitygraph_array {}
		# si aucun score n'existe pour la période en cours...
		if {$::motus::scores eq ""} {
			set activitygraph_max [set activitygraph_array(0) 0]
		# sinon, si des scores ont été enregistrés pour la période en cours...
		} else {
			set activitygraph_max [set activitygraph_array(0) [expr [join [regsub -all { \| [^\ ]+} " | [motus::restore_nick [join $::motus::scores " | "]]" ""] "+"]]]
		}
		if { [set historylength [expr [llength [split $read_scores_archive "\n"]]-1]] > 51 } { set historylength 51 }
		for { set counter 1 } { $counter <= $historylength } { incr counter } {
			if { [::tcl::string::match "Aucun score *" [set scores_range [join [lrange [lindex [split $read_scores_archive "\n"] end-$counter] 5 end]]]] } {
				set scores_range {personne 0}
			}
			set activitygraph_array($counter) [expr [join [regsub -all { \| [^\s]+ -?} " | $scores_range" " "] "+"]]
			if { $activitygraph_max < $activitygraph_array($counter) } { set activitygraph_max $activitygraph_array($counter) }
		}
		set split_read_scores_archive [split $read_scores_archive "\n"]
		for { set counter 0 } { $counter <= 51 } { incr counter } {
			if { ![::tcl::info::exists activitygraph_array($counter)]} { set activitygraph_array($counter) 0 }
			regsub -all -nocase "%GRAPHVALUE$counter%" $read_template $activitygraph_array($counter) read_template
			regsub -all -nocase "%GRAPHPERCENT$counter%" $read_template [expr (($activitygraph_array($counter) * 100) / $activitygraph_max)] read_template
			if { $counter == 0 } {
				regsub -all -nocase "%GRAPHPERIOD0%" $read_template "p\\&eacute;riode en cours depuis le [lindex [lindex $split_read_scores_archive end-1] 3]" read_template
			} else {
				regsub -all -nocase "%GRAPHPERIOD$counter%" $read_template [lrange [lindex $split_read_scores_archive end-$counter] 0 3] read_template
			}
		}
		# Added by CC : use expformat if exists
		if {[llength [info procs [namespace current]::expformat]]==1} {
			set reverse_scores_archive [namespace current]::expformat $read_scores_archive
		} else {
		# End of addition by CC
			regsub -all -nocase {\n} "<p> $read_scores_archive </p>" " </p>\n@<p> " read_scores_archive
			set read_scores_archive [split $read_scores_archive "@"]
			# on trie les scores archivés par ordre chronologique inverse
			set reverse_scores_archive {}
			set reverse_counter [llength $read_scores_archive]
			while {$reverse_counter > 0} {
				lappend reverse_scores_archive [lindex $read_scores_archive [incr reverse_counter -1]]
			}
			set reverse_scores_archive [join [join $reverse_scores_archive]]
			regsub -all {du [0-9]+/[0-9]+/[0-9]+-[0-9]+:[0-9]+:[0-9]+ au [0-9]+/[0-9]+/[0-9]+-[0-9]+:[0-9]+:[0-9]+} $reverse_scores_archive  "<span class=\"tounderline\">&</span>" reverse_scores_archive
		} # Added by CC : must clocse the else
	# sinon, s'il n'existe pas d'archives des scores des périodes précédentes...
	} else {
		set reverse_scores_archive "Aucun score n'a \\&eacute;t\\&eacute; enregistr\\&eacute; durant les semaines pr\\&eacute;c\\&eacute;dentes."
		for { set counter 0 } { $counter <= 51 } { incr counter } {
			if {($counter == 0) && ($::motus::scores ne "")} {
				regsub -all -nocase "%GRAPHPERCENT0%" $read_template [expr (([set current_week [expr [join [regsub -all { \| [_\-\[\]\(\)\{\}\^\|`a-zA-Z0-9]+} " | [motus::restore_nick [join $::motus::scores " | "]]" ""] "+"]]] * 100) / $current_week)] read_template
				regsub -all -nocase "%GRAPHVALUE0%" $read_template [expr [join [regsub -all { \| [_\-\[\]\(\)\{\}\^\|`a-zA-Z0-9]+} " | [motus::restore_nick [join $::motus::scores " | "]]" ""] "+"]] read_template
				regsub -all -nocase "%GRAPHPERIOD0%" $read_template "p\\&eacute;riode en cours depuis le [strftime "%d/%m/%Y-%H:%M:%S" $::motus::stat_reference_time]" read_template
			} else {					
				regsub -all -nocase "%GRAPHPERCENT$counter%" $read_template "0" read_template
				regsub -all -nocase "%GRAPHVALUE$counter%" $read_template "0" read_template
				regsub -all -nocase "%GRAPHPERIOD$counter%" $read_template "" read_template
			}
		}
	}
	regsub -all -nocase {%SCORES.ARCHIVE%} $read_template $reverse_scores_archive read_template
	regsub -all -nocase {%FOOTER1%} $read_template $::motus::html_footer1 read_template
	regsub -all -nocase {%FOOTER2%} $read_template $::motus::html_footer2 read_template
	regsub -all -nocase {%VERSION%} $read_template $::motus::version read_template
	# copie des fichiers du template dans le répertoire d'exportation
	foreach currentfile [glob -nocomplain [file join $::motus::html_template_path *]] {
		set tail [file tail $currentfile]
		if { $tail eq "expformat.tcl" } { continue } # Added by CC : do not copy expformat.tcl
		if { $tail eq "index.html" } {
			set tail $::motus::html_filename
		} elseif { $tail eq "style.css" } {
			set tail $::motus::css_filename
		}
		set dest [file join $::motus::html_export_path $tail]
		file copy -force -- $currentfile $dest
	}
	# écriture du fichier index.html avec les variables substituées
	set fichiertemplateout [open "[set ::motus::html_export_path][set ::motus::html_filename]" w]
	puts $fichiertemplateout [encoding convertfrom identity [motus::html_accent_filter $read_template]]
	close $fichiertemplateout
	if {($::motus::html_export) && ($arg eq "auto")} {
		if {[set htmltimer [motus::timerexists {::motus::html_export "auto"}]] ne ""} { killtimer $htmltimer }
		timer $::motus::html_export_interval {::motus::html_export "auto"}
	}
	return
}

##### Annonces entre 2 rounds
proc ::motus::announce {} {
	# on choisit une annonce au hasard
	set announce [lindex $::motus::announce_statements [lindex $::motus::announce_indexes $::motus::current_announce_index]]
	incr ::motus::current_announce_index
	if { $::motus::current_announce_index >= [llength $::motus::announce_statements] } { set ::motus::current_announce_index 0 }
	# moulinette pour remplacer le noms des variables par leur valeur
	regsub -all {%reference.time.hour%} $announce "[code stop][code announce_special]\002[strftime "%H:%M:%S" $::motus::stat_reference_time]\002[code stop][code announce]" announce
	regsub -all {%reference.time.date%} $announce "[code stop][code announce_special]\002[strftime "%d/%m/%Y" $::motus::stat_reference_time]\002[code stop][code announce]" announce
	regsub -all {%reference.time%} $announce "[strftime "[code stop][code announce_special]\002%d/%m/%Y\002[code stop][code announce] à [code stop][code announce_special]\002%H:%M:%S\002" $::motus::stat_reference_time][code stop][code announce]" announce
	regsub -all {%last.update.hour%} $announce "[code stop][code announce_special]\002[strftime "%H:%M:%S" $::motus::stat_last_update]\002[code stop][code announce]" announce
	regsub -all {%last.update.date%} $announce "[code stop][code announce_special]\002[strftime "%d/%m/%Y" $::motus::stat_last_update]\002[code stop][code announce]" announce
	regsub -all {%last.update%} $announce "[strftime "[code stop][code announce_special]\002%d/%m/%Y\002[code stop][code announce] à [code stop][code announce_special]\002%H:%M:%S\002" $::motus::stat_last_update][code stop][code announce]" announce
	if { $::motus::stat_last_scores_reset == 0 } {
		regsub -all {%last.scores.reset.hour%} $announce "[code stop][code announce_special]\002n/c\002[code stop][code announce]" announce
		regsub -all {%last.scores.reset.date%} $announce "[code stop][code announce_special]\002n/c\002[code stop][code announce]" announce
		regsub -all {%last.scores.reset%} $announce "[code stop][code announce_special]\002n/c\002[code stop][code announce]" announce
	} else {
		regsub -all {%last.scores.reset.hour%} $announce "[code stop][code announce_special]\002[strftime "%H:%M:%S" $::motus::stat_last_scores_reset]\002[code stop][code announce]" announce
		regsub -all {%last.scores.reset.date%} $announce "[code stop][code announce_special]\002[strftime "%d/%m/%Y" $::motus::stat_last_scores_reset]\002[code stop][code announce]" announce
		regsub -all {%last.scores.reset%} $announce "[strftime "[code stop][code announce_special]\002%d/%m/%Y\002[code stop][code announce] à [code stop][code announce_special]\002%H:%M:%S\002" $::motus::stat_last_scores_reset][code stop][code announce]" announce
	}
	regsub -all {%cycleday%} $announce "[code stop][code announce_special]\002$::motus::clearscores_day\002[code stop][code announce]" announce
	regsub -all {%cycletime%} $announce "[code stop][code announce_special]\002[join $::motus::clearscores_time "h"]\002[code stop][code announce]" announce
	regsub -all {%week.champ.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex $::motus::stat_week_champ 1]]\002[code stop][code announce]" announce
	regsub -all {%week.champ.score%} $announce "[code stop][code announce_special]\002[lindex $::motus::stat_week_champ 0]\002[code stop][code announce]" announce
	if { [lindex $::motus::stat_week_champ 0] eq "0" } {
		regsub -all {%week.champ%} $announce "[code stop][code announce_special]\002personne\002[code stop][code announce]" announce
	} else {
		regsub -all {%week.champ%} $announce "\002[motus::restore_nick [lindex $::motus::stat_week_champ 1]] [code stop][code announce_special][lindex $::motus::stat_week_champ 0]\002[code stop][code announce]" announce
	}
	regsub -all {%last.week.champ.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex $::motus::stat_last_week_champ 1]]\002[code stop][code announce]" announce
	regsub -all {%last.week.champ.score%} $announce "[code stop][code announce_special]\002[lindex $::motus::stat_last_week_champ 0]\002[code stop][code announce]" announce
	if { [lindex $::motus::stat_last_week_champ 0] eq "0" } {
		regsub -all {%last.week.champ%} $announce "[code stop][code announce_special]\002personne\002[code stop][code announce]" announce
	} else {
		regsub -all {%last.week.champ%} $announce "\002[motus::restore_nick [lindex $::motus::stat_last_week_champ 1]] [code stop][code announce_special][lindex $::motus::stat_last_week_champ 0]\002[code stop][code announce]" announce
	}
	regsub -all {%all.time.top3.1.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 0] 0]]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.1.score%} $announce "[code stop][code announce_special]\002[lindex [lindex $::motus::stat_all_time_top3 0] 1]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.2.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 1] 0]]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.2.score%} $announce "[code stop][code announce_special]\002[lindex [lindex $::motus::stat_all_time_top3 1] 1]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.3.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 2] 0]]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.3.score%} $announce "[code stop][code announce_special]\002[lindex [lindex $::motus::stat_all_time_top3 2] 1]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.1%} $announce "\002[motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 0] 0]] [code stop][code announce_special][lindex [lindex $::motus::stat_all_time_top3 0] 1]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.2%} $announce "\002[motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 1] 0]] [code stop][code announce_special][lindex [lindex $::motus::stat_all_time_top3 1] 1]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3.3%} $announce "\002[motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 2] 0]] [code stop][code announce_special][lindex [lindex $::motus::stat_all_time_top3 2] 1]\002[code stop][code announce]" announce
	regsub -all {%all.time.top3%} $announce "\002[motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 0] 0]] [code stop][code announce_special][lindex [lindex $::motus::stat_all_time_top3 0] 1][code stop][code announce]   [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 1] 0]] [code stop][code announce_special][lindex [lindex $::motus::stat_all_time_top3 1] 1][code stop][code announce]   [motus::restore_nick [lindex [lindex $::motus::stat_all_time_top3 2] 0]] [code stop][code announce_special][lindex [lindex $::motus::stat_all_time_top3 2] 1]\002[code stop][code announce]" announce
	regsub -all {%most.champ.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex $::motus::stat_most_champ 1]]\002[code stop][code announce]" announce
	regsub -all {%most.champ.score%} $announce "[code stop][code announce_special]\002[lindex $::motus::stat_most_champ 0]\002[code stop][code announce]" announce
	if { [lindex $::motus::stat_most_champ 0] eq "0" } {
		regsub -all {%most.champ%} $announce "[code stop][code announce_special]\002personne\002[code stop][code announce]" announce
	} else {
		regsub -all {%most.champ%} $announce "\002[motus::restore_nick [lindex $::motus::stat_most_champ 1]] [code stop][code announce_special][lindex $::motus::stat_most_champ 0]\002[code stop][code announce]" announce
	}
	regsub -all {%best.finder.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex $::motus::stat_best_finder 1]]\002[code stop][code announce]" announce
	regsub -all {%best.finder.score%} $announce "[code stop][code announce_special]\002[lindex $::motus::stat_best_finder 0]\002[code stop][code announce]" announce
	if { [lindex $::motus::stat_best_finder 0] eq "0" } {
		regsub -all {%best.finder%} $announce "[code stop][code announce_special]\002personne\002[code stop][code announce]" announce
	} else {
		regsub -all {%best.finder%} $announce "\002[motus::restore_nick [lindex $::motus::stat_best_finder 1]] [code stop][code announce_special][lindex $::motus::stat_best_finder 0]\002[code stop][code announce]" announce
	}
	regsub -all {%fastest.play.name%} $announce "[code stop][code announce_special]\002[motus::restore_nick [lindex $::motus::stat_fastest_play 1]]\002[code stop][code announce]" announce
	regsub -all {%fastest.play.score%} $announce "[code stop][code announce_special]\002[lindex $::motus::stat_fastest_play 0]\002[code stop][code announce]" announce
	if { [lindex $::motus::stat_fastest_play 0] eq "0" } {
		regsub -all {%fastest.play%} $announce "[code stop][code announce_special]\002personne\002[code stop][code announce]" announce
	} else {
		regsub -all {%fastest.play%} $announce "\002[motus::restore_nick [lindex $::motus::stat_fastest_play 1]] [code stop][code announce_special][lindex $::motus::stat_fastest_play 0]\002[code stop][code announce]" announce
	}
	regsub -all {%total.rounds%} $announce "[code stop][code announce_special]\002$::motus::stat_total_rounds\002[code stop][code announce]" announce
	regsub -all {%wordlistcount%} $announce "[code stop][code announce_special]\002$::motus::totalmots\002[code stop][code announce]" announce
	regsub -all {%dicocount%} $announce "[code stop][code announce_special]\002$::motus::totalmotsverif\002[code stop][code announce]" announce
	regsub -all {%minmaxlength%} $announce "[code stop][code announce_special]\002$::motus::minmaxlength\002[code stop][code announce]" announce
	regsub -all {%ptsletterfound%} $announce "[code stop][code announce_special]\002$::motus::pts_letter_found\002[code stop][code announce]" announce
	regsub -all {%ptsletterplaced%} $announce "[code stop][code announce_special]\002$::motus::pts_letter_placed\002[code stop][code announce]" announce
	regsub -all {%ptswordfound%} $announce "[code stop][code announce_special]\002$::motus::pts_word_found\002[code stop][code announce]" announce
	regsub -all {%speed_reward%} $announce "[code stop][code announce_special]\002[if {$::motus::speed_reward} {set dummy activé} {set dummy désactivé}]\002[code stop][code announce]" announce
	regsub -all {%speed_bonus_10%} $announce "[code stop][code announce_special]\002$::motus::speed_bonus_10\002[code stop][code announce]" announce
	regsub -all {%speed_bonus_20%} $announce "[code stop][code announce_special]\002$::motus::speed_bonus_20\002[code stop][code announce]" announce
	regsub -all {%speed_bonus_35%} $announce "[code stop][code announce_special]\002$::motus::speed_bonus_35\002[code stop][code announce]" announce
	regsub -all {%speed_bonus_50%} $announce "[code stop][code announce_special]\002$::motus::speed_bonus_50\002[code stop][code announce]" announce
	regsub -all {%losepoints%} $announce "[code stop][code announce_special]\002[if {$::motus::lose_points} {set dummy activé} {set dummy désactivé}]\002[code stop][code announce]" announce
	regsub -all {%saidlostpoints%} $announce "[code stop][code announce_special]\002[if {$::motus::said_lost_points} {set dummy -} {set dummy ""}]\002\002[set ::motus::said_lost_points]\002[code stop][code announce]" announce
	regsub -all {%inexistantlostpoints%} $announce "[code stop][code announce_special]\002[if {$::motus::inexistant_lost_points} {set dummy -} {set dummy ""}]\002\002[set ::motus::inexistant_lost_points]\002[code stop][code announce]" announce
	regsub -all {%nulllostpoints%} $announce "[code stop][code announce_special]\002[if {$::motus::null_lost_points} {set dummy -} {set dummy ""}]\002\002[set ::motus::null_lost_points]\002[code stop][code announce]" announce
	regsub -all {%hinttime%} $announce "[code stop][code announce_special]\002$::motus::hint_time\002[code stop][code announce]" announce
	regsub -all {%maxhints%} $announce "[code stop][code announce_special]\002$::motus::max_hints\002[code stop][code announce]" announce
	regsub -all (%day%) $announce "[::tcl::string::map -nocase {Mon lundi Tue mardi Wed mercredi Thu jeudi Fri vendredi Sat samedi Sun dimanche} [strftime "%a" [unixtime]]]" announce
	regsub -all {%time%} $announce "[code stop][code announce_special]\002[strftime "%H:%M:%S"]\002[code stop][code announce]" announce
	regsub -all {%year%} $announce "[code stop][code announce_special]\002[strftime "%Y"]\002[code stop][code announce]" announce
	regsub -all {%date%} $announce "[code stop][code announce_special]\002[strftime "%d/%m/%Y"]\002[code stop][code announce]" announce
	regsub -all (%botnick%) $announce "[code stop][code announce_special]\002$::botnick\002[code stop][code announce]" announce
	regsub -all {%chan%} $announce "[code stop][code announce_special]\002$::motus::motus_chan\002[code stop][code announce]" announce
	regsub -all {%htmlupdateinterval%} $announce "[code stop][code announce_special]\002$::motus::html_export_interval\002[code stop][code announce]" announce
	regsub -all {%randnick%} $announce [lindex [set nicklist [lreplace [set nicklist2 [chanlist $::motus::motus_chan]] [set index [lsearch -exact $nicklist2 $::botnick]] $index]] [rand [llength $nicklist]]] announce
	regsub -all {%config_profile%} $announce "[code stop][code announce_special]\002[set ::motus::profile_name]\002[code stop][code announce]" announce
	regsub -all {%profile_description%} $announce "$::motus::profile_description" announce
	regsub -all {%num_achievements%} $announce "[code stop][code announce_special]\002[set ::motus::num_achievements]\002[code stop][code announce]" announce
	regsub -all {%total_achievements_points%} $announce "[code stop][code announce_special]\002[set ::motus::max_achievements_points]\002[code stop][code announce]" announce
	regsub -all {%b%} $announce "\002" announce
	regsub -all {%u%} $announce "\037" announce
	regsub -all {%i%} $announce "\026" announce
	regsub -all {%c%} $announce "[code stop]" announce
	# affichage de l'annonce
	::motus::putqueue "PRIVMSG $::motus::motus_chan :[code announce] $announce [code stop]"
	return
}

##### Surveillance des changements de nick
proc ::motus::nickchange {nick host hand chan newnick} {
	variable nickchange_array
	array set nickchange_array {}
	set cleannewnick [motus::clean_nick $newnick]
	# On crée un array de la forme nickchange_array($cleannewnick) = $cleanoldnick
	# Ce tableau sera lu chaque fois qu'un joueur fait une proposition valide
	# pour détecter si il a changé de pseudo afin d'opérer les renommages/fusions
	# nécessaires.
	#
	# Si une entrée inverse existe déjà dans l'array, on la supprime et on n'en crée pas de nouvelle
	if {([::tcl::info::exists nickchange_array([set cleanoldnick [motus::clean_nick $nick]])]) && ($nickchange_array($cleanoldnick) eq $cleannewnick)} {
		unset nickchange_array($cleanoldnick)
	# sinon, si deux entrées peuvent être factorisées, on le fait
	} elseif {[lsearch [::tcl::string::tolower [array names nickchange_array]] [::tcl::string::tolower $cleanoldnick]] != -1} {
		set nickchange_array($cleannewnick) $nickchange_array($cleanoldnick)
		unset nickchange_array($cleanoldnick)
	# sinon on ajoute simplement une entrée
	} else {
		set nickchange_array($cleannewnick) $cleanoldnick
	}
	if { ([lsearch $::motus::scores "[motus::clean_nick $newnick] *"] != -1) && ($::motus::warn_on_fusion) } {
		::motus::putlog_split_line  "\00304\002\[Motus - info\]\002\003\00307 $nick\003\00314![getchanhost $newnick] ([nick2hand $newnick])\003 s'est renommé en\00307 $newnick\003. \037Remarque\037 : un score existe déjà à ce nom :\00314 $::motus::scores\003"
	}
}

##### Affiche l'état du jeu aux nouveaux arrivants
proc ::motus::onjoin {nick host hand chan} {
	if { [channel get $::motus::motus_chan motus] == 0 } {
		return
	} else {
		if { $::motus::status == 1 } {
			putserv "NOTICE $nick :Bienvenue \002${nick}\002. Une partie de Motus est en cours avec le profil de configuration \002$::motus::profile_name\002, voici l'état du jeu :"
			putserv "NOTICE $nick :[code gimmick]::::|   [code stop][code commonletter]\002$::motus::masque\002[code stop][code gimmick]   |::::[code stop]  [code normaltext]([llength $::motus::masque] lettres)[code stop]"
		} elseif { $::motus::status == 2 } {
			putserv "NOTICE $nick :Bienvenue \002${nick}\002. Une partie de Motus est en cours avec le profil de configuration \002$::motus::profile_name\002, le prochain round va bientôt démarrer..."
		} else {
			return
		}
	}
}

##### On convertit les statistiques des joueurs du format pré-v2.2 au format v2.2 si nécessaire
proc ::motus::convert_player_stats_to_v2_2_if_needed {} {
	if {(([file exists $::motus::finder_file]) || ([file exists $::motus::champ_file])) && (![file exists $::motus::playerstats_file])} {
		::motus::stats do read.stats - - -
		array set imported_player_stats {}
		putloglev o * "\00304\002\[Motus - info\]\002\003 Des fichiers de statistiques des joueurs d'un ancien format (antérieur à la version 2.2 du Motus) ont été trouvés et convertis automatiquement au nouveau format. Une copie de sauvegarde des anciens fichiers a été effectuée par sécurité, vous les trouverez ici : [set ::motus::champ_file].old | [set ::motus::finder_file].old"
		# on importe les stats de comptage des rounds gagnés dans l'array $imported_player_stats
		if {[file exists $::motus::finder_file]} {
			set fichierfinder [open $::motus::finder_file r]
			set read_finders [read -nonewline $fichierfinder]
			close $fichierfinder
			set read_finders [split $read_finders "\n"]
			for { set counter 0 } { $counter <= [llength $read_finders] } { incr counter } {
				if {[lindex [split [lindex $read_finders $counter] ","] 1] ne ""} {
					append imported_player_stats([lindex [split [lindex $read_finders $counter] ","] 1]) [lindex [split [lindex $read_finders $counter] ","] 0]
				}
			}
		}
		# on ajoute les stats de comptage des titres de champion dans l'array $imported_player_stats
		if {[file exists $::motus::champ_file]} {
			set fichierchamp [open $::motus::champ_file r]
			set read_champs [read -nonewline $fichierchamp]
			close $fichierchamp
			set read_champs [split $read_champs "\n"]
			for { set counter 0 } { $counter <= [llength $read_champs] } { incr counter } {
				if {[set name [lindex [split [lindex $read_champs $counter] ","] 1]] ne ""} {
					# cas où le joueur possède des stats de comptage de rounds gagnés
					if {[::tcl::info::exists imported_player_stats($name)]} {
						append imported_player_stats($name) ",[lindex [split [lindex $read_champs $counter] ","] 0]"
					# cas où le joueur n'a pas de stats de rounds gagnés (ce qui ne devrait normalement jamais
					# arriver si il a au moins un titre de champion, mais c'est juste au cas où.
					} else {
						append imported_player_stats($name) "0,[lindex [split [lindex $read_champs $counter] ","] 0]"
					}
				}
			}
		}	
		# on formatte correctement l'array $imported_player_stats et on constitue la liste
		# qui sera finalement écrite dans player.stats
		set array_search_ID [array startsearch imported_player_stats]
		while { [array anymore imported_player_stats $array_search_ID] } {
			set name [array nextelement imported_player_stats $array_search_ID]
			# cas où les champs "nombre de rounds gagnés" ET "nombre de fois champion" sont renseignés
			if { [::tcl::string::match "*,*" $imported_player_stats($name)] } {
				append imported_player_stats($name) ",0,0,0,0,0"
			# cas où seul le champ "nombre de rounds gagnés" est renseigné
			} else {
				append imported_player_stats($name) ",0,0,0,0,0,0"
			}
			# on ajuste le meilleur temps pour le joueur le plus rapide
			if { [::tcl::string::tolower $name] eq [::tcl::string::tolower [lindex $::motus::stat_fastest_play 1]] } {
				append imported_player_stats($name) ",[lindex $::motus::stat_fastest_play 0]"
			} else {
				append imported_player_stats($name) ",0"
			}
			lappend player_stats "$name,$imported_player_stats($name)"
		}
		array donesearch imported_player_stats $array_search_ID
		# on insère l'entête du fichier de statistiques des joueurs
		set player_stats [linsert $player_stats 0 "!#v$::motus::version:$::botnick"]
		# on trie le nouveau fichier de statistiques des joueurs et on l'écrit
		set player_stats [lsort -dict $player_stats]
		set fichierplayerstats [open $::motus::playerstats_file w]
		puts $fichierplayerstats [join $player_stats "\n"]
		close $fichierplayerstats
		file rename -force -- $::motus::finder_file "[set ::motus::finder_file].old"
		file rename -force -- $::motus::champ_file "[set ::motus::champ_file].old"
	}
}

##### Affichage de la définition d'un mot
proc ::motus::dico {mot} {
	set unformatted_word $mot
	if {$::motus::DEBUGMODE} { putlog "\00304\002\[Motus - debug\]\002\003Affichage de la définition du mot \002$unformatted_word\002" }
	::http::register https 443 [list ::tls::socket -tls1 1]
	# on modifie l'urlencoding car notre-famille.com ne comprend pas l'utf-8 dans ses URLs
	array set httpconfig [::http::config]
	::http::config -urlencoding iso8859-1 -useragent $::motus::useragent
	# On remplace les caractères spéciaux par leur équivalent hexadécimal pour
	# pouvoir être utilisés dans l'url.
	set mot [::http::mapReply $mot]
	# on restaure l'urlencoding comme il était avant qu'on y touche
	::http::config -urlencoding $httpconfig(-urlencoding)
	set url [subst $::motus::dictionary_parse_URL]
	if { [catch { set token [::motus::geturl $url -timeout [expr $::motus::definition_timeout * 1000]] }] } {
		putloglev o * "\00304\002\[Motus - avertissement\]\002\003 La connexion à \00312\037http://www.notre-famille.com\037\003 n'a pas pu être établie. Impossible d'afficher la définition du mot \002$unformatted_word\002."
	} elseif { [::http::status $token] eq "timeout" } {
		if {$::motus::DEBUGMODE} { putloglev o * "\00304\002\[Motus - avertissement\]\002\003 La connexion à \00312\037http://www.notre-famille.com\037\003 n'a pas pu être établie dans le temps imparti. Impossible d'afficher la définition du mot \002$unformatted_word\002." }
	} elseif { [::http::status $token] eq "ok" } {
		set received_data [::http::data $token]
		if { (![regexp {id=\"mediadico-def\">} $received_data])
			|| ([regexp {<div id=\"error_message\">} $received_data])
			|| ([regexp {<p class=\"erreur\">} $received_data])
		} then {
			::motus::output_public_message 1 {} [code defcolor1] "[code normaltext]Impossible de trouver une définition dans le dictionnaire en ligne.[code stop]"
			::http::cleanup $token
			::http::unregister https
			return
		}
		if { ([::tcl::info::exists received_data]) && ($received_data ne "") } {
			set anti_infinite_loop_counter 1
			# Si on tombe sur une page permettant de choisir entre plusieurs mots celui qu'on veut,
			# on choisit par défaut le 1er sens proposé et on charge la nouvelle page
			while { [regexp {<h2 class="grostitre-bande">(\s+|\n+)?R.sultats de votre recherche pour \".+?\"(\s+|\n+)?</h2>} $received_data] } {
				::http::cleanup $token
				::http::unregister https
				regexp {<ul class="dictionnaire-recherche-list">(.+?)</li>} $received_data {} received_data
				regexp {<a href=\"(.+?)\">(.+?)</a>} $received_data {} url word
				set mot [::http::mapReply [::motus::html_filter $word]]
				if { [catch { set token [::motus::geturl $url -timeout [expr $::motus::definition_timeout * 1000]] }] } {
					putloglev o * "\00304\002\[Motus - avertissement\]\002\003 La connexion à \00312\037http://www.notre-famille.com\037\003 n'a pas pu être établie. Impossible d'afficher la définition du mot \002$unformatted_word\002."
					::http::cleanup $token
					::http::unregister https
					return
				} elseif { [::http::status $token] eq "timeout" } {
					if {$::motus::DEBUGMODE} { putloglev o * "\00304\002\[Motus - avertissement\]\002\003 La connexion à \00312\037http://www.notre-famille.com\037\003 n'a pas pu être établie dans le temps imparti. Impossible d'afficher la définition du mot \002$unformatted_word\002." }
					::http::cleanup $token
					::http::unregister https
					return
				} elseif { [::http::status $token] eq "ok" } {
					set received_data [::http::data $token]
				}
				incr anti_infinite_loop_counter 1
				if { $anti_infinite_loop_counter == 6 } {
					if {$::motus::DEBUGMODE} { putloglev o * "\00304\002\[Motus - avertissement\]\002\003 Cascade de redirections (> 5) interrompue lors de la récupération de la définition du mot \002$unformatted_word\002." }
					break
				}
			}
			# on extrait la partie qui nous intéresse et sur laquelle on va travailler
			regexp {<a name=\"mediadico-def\">(.+?)<div class=\"pub-mediadico\"} $received_data {} received_data
			# on enlève ce qui ne nous intéresse pas
			regsub -all {(<p class=\"synonyme\">.+?</p>)} $received_data "" received_data
			regsub -all {(<ul class=\"voir-aussi-liste\">.+?</ul>)} $received_data "" received_data
			regsub -all {(<div class=\"hreview\">.+?</div>)} $received_data "" received_data
			regsub -all {(<div id=\"vote\">.+?</div>)} $received_data "" received_data
			set counter 1
			# récupération des différents sens du mot
			while { [regsub -all {((\n|\s)+|<[^<]*>)} $received_data ""] ne "" } {
				regexp {<h2 class=\"definition-word\">.+?(<h2|<script)} $received_data section($counter)
				if { ![::tcl::info::exists section($counter)] } {
					break
				}
				regsub {<h2 class=\"definition-word\">.+?(<h2|<script)} $received_data {\1} received_data
				# extraction du mot / classe
				regexp {<h2 class="definition-word">(.+?)<span>\((.+?)\)</span>(?:\s+)?</h2>} $section($counter) {} subword($counter) word_class($counter)
				if {
					!([::tcl::info::exists subword($counter)])
					|| !([::tcl::info::exists word_class($counter)])
				} then {
					unset section($counter)
					break
				}
				set subword($counter) [::motus::html_filter $subword($counter)]
				set word_class($counter) [::tcl::string::map {
					"nom masculin" "n.m." "nom féminin" "n.f." "adjectif masculin" "adj.m." "adjectif féminin" "adj.f."
					"nom commun" "n. comm."	"adjectif" "adj." "adverbe" "adv." "préposition" "prép." "pronominal" "pronominal"
					"pronom" "pron." "article" "art." "numéral" "num." "invariable" "inv." "verbe" "v." "impersonnel" "impers."
					"possessif" "poss." "transitif" "tr." "intransitif" "intr." "symbole" "symb." "défini" "déf."
					"indéfini" "indéf." "démonstratif" "démonstr." "pluriel" "plur." "interrogatif" "interr."
					"exclamatif" "excl." "personnel" "pers." "relatif" "rel." "expression" "expr."
					"conjonction" "conj." "interjection" "interj." "locution" "loc."
				} [::motus::html_filter $word_class($counter)]]
				# extraction de la définition
				regexp {<p class=\"definition\">.+?</p>} $section($counter) definition($counter)
				regsub -all {<br ?/><br ?/>(?!\n)} $definition($counter) " \00314/\003 " definition($counter)
				regsub {<br ?/><br ?/>\n.*$} $definition($counter) "" definition($counter)
				regsub -all {<[^<]*>} $definition($counter) "" definition($counter)
				set definition($counter) [::tcl::string::map {\{ \[ \} \]} $definition($counter)]
				regsub -all {\s+} $definition($counter) " " definition($counter)
				set definition($counter) [::tcl::string::trim [::motus::html_filter [::motus::html_filter $definition($counter)]] " "]
				incr counter
				if { $counter > 20 } {
					putloglev o * "\00304\002\[Motus - erreur\]\002\003 Un problème a été rencontré lors de la récupération de la définition du mot $unformatted_word : boucle infinie."
					::http::cleanup $token
					::http::unregister https
					return
				}
			}
			if { ![::tcl::info::exists definition(1)] } {
				putloglev o * "\00304\002\[Motus - erreur\]\002\003 Un problème a été rencontré lors de la récupération de la définition du mot $unformatted_word : aucune donnée exploitable n'a pu être récupérée."
				::http::cleanup $token
				::http::unregister https
				return
			}
			### affichage du résultat de la recherche
			set has_been_truncated 0
			for { set counter 1 } { $counter <= [array size section] } { incr counter } {
				if { $counter == 1 } {
					if { [set num_meanings [array size section]] == 1 } {
						append output "\002$subword(1)\002\00314 $word_class($counter)\003 : $definition($counter)"
					} else {
						append output "\00314\002\002$counter -\003 \002$subword(1)\002\00314 $word_class($counter)\003 : $definition($counter)"
					}
				} else {
					if { $subword([expr {$counter-1}]) eq $subword($counter) } {
						append output " \00307|\003\00314 $counter - $word_class($counter)\003 : $definition($counter)"
					} else {
						append output " \00307|\003\00314 $counter -\003 \002$subword($counter)\002\00314 $word_class($counter)\003 : $definition($counter)"
					}
				}
			}
			if { [::motus::output_public_message 1 $::motus::definitions_max_lines [code defcolor1] "[code defcolor1][set output]"] } { set has_been_truncated 1 }
			if { ($::motus::show_definition_link) && ($has_been_truncated) } {
				if { $::motus::shorten_URLs } {
					set referral_URL [::motus::tinyurl_conversion $url]
				} else {
					set referral_URL $url
				}	
				::motus::output_public_message 1 0 {} "[code defcolor4]Vous pouvez consulter la définition intégrale ici : [code urlcolor][code u][set referral_URL][code u][code stop]"
			}
		} else {
			putloglev o * "\00304\002\[Motus - erreur\]\002\003 Echec du parser HTML : le site \00312\037[subst $::motus::dictionary_parse_URL]\037\003 n'a retourné aucune donnée exploitable. Impossible d'afficher la définition du mot \002$unformatted_word\002."
		}
	}
	if {[::tcl::info::exists token]} { ::http::cleanup $token }
	::http::unregister https
}

 ###############################################################################
### Proc geturl avec suivi des redirections http (©ealexp)
 ###############################################################################
proc ::motus::geturl {url args} {
	::http::config -useragent $::motus::useragent
	# On récupère l'hôte de l'URL d'origine, au cas où il ne serait plus spécifié dans la redirection.
	set original_url_host [lindex [regexp -inline {http://(.*?)/} $url] 0]
	# On suit au maximum 5 redirections.
	for {set i 0} {$i < 5} {incr i} {
		if {[::tcl::info::exists token]} { ::http::cleanup $token }
		set token [::http::geturl $url {*}$args]
		if {![string match {30[1237]} [::http::ncode $token]]} {
			break
		}
		set meta [set ${token}(meta)]
		if {![dict exists $meta Location]} {
			break
		}
		set url [dict get $meta Location]
		if {[string match {//*} $url]} {
			set url "http:$url"
		} elseif {[regexp -inline {http://(.*?)/} $url] eq ""} {
			set url $original_url_host$url
		}
	}
	return $token
}

##### Nettoie les caractères spéciaux dans les pseudos
proc ::motus::clean_nick {nick} {
	return [::tcl::string::map {
		"\[" "@1" "\]" "@2"
		"\\" "@3" "\|" "@4"
		"\{" "@5" "\}" "@6"
		"\^" "@7" "\$" "@8"
	} $nick]
}
##### Restaure les caractères spéciaux dans les pseudos
proc ::motus::restore_nick {nick} {
	return [::tcl::string::map {
		"@1" "\[" "@2" "\]"
		"@3" "\\" "@4" "\|"
		"@5" "\{" "@6" "\}"
		"@7" "\^" "@8" "\$"
	} $nick]
}

##### Filtrage des codes de contrôle et des espaces superflus
proc ::motus::strip_codes_and_spaces {text} { 
	return [::tcl::string::trim [regsub -all {\s+} [::tcl::string::map {"\017" ""} [stripcodes abcgru $text]] " "]]
} 

##### mise en majuscules et suppression des accents éventuels
proc ::motus::formate_mot {motchoisi} {
	return [::tcl::string::toupper [::tcl::string::map {
		"à" "a" "â" "a" "ä" "a"
		"é" "e" "è" "e" "ê" "e" "ë" "e"
		"î" "i" "ï" "i"
		"ô" "o" "ö" "o"
		"ù" "u" "û" "u" "ü" "u"
		"ç" "c" "ñ" "n" "ã" "a" "õ" "o"
	} $motchoisi]]
}

##### mise en majuscule (y compris les accents)
proc ::motus::toupper {mot} {
	return [::tcl::string::toupper [::tcl::string::map {
		"à" "À" "â" "Â" "ä" "Ä"
		"é" "É" "è" "È" "ê" "Ê" "ë" "Ë"
		"î" "Î" "ï" "Ï"
		"ô" "Ô" "ö" "Ö"
		"ù" "Ù" "û" "Û" "ü" "Ü"
		"ç" "Ç" "ñ" "Ñ" "ã" "Ã" "õ" "Õ"
	} $mot]]
}

##### Conversion des caractères unicode en codes html
proc ::motus::html_accent_filter {res} {
	set res [::tcl::string::map {
		"à"		"&agrave;"		"à"		"&agrave;"		"á"		"&aacute;"		"â"		"&acirc;"
		"ã"		"&atilde;"		"ä"		"&auml;"			"å"		"&aring;"			"æ"		"&aelig;"			
		"ç"		"&ccedil;"		"è"		"&egrave;"		"é"		"&eacute;"		"ê"		"&ecirc;"
		"ë"		"&euml;"			"ì"		"&igrave;"		"í"		"&iacute;"		"î"		"&icirc;"
		"ï"		"&iuml;"			"ð"		"&eth;"				"ñ"		"&ntilde;"		"ò"		"&ograve;"
		"ó"		"&oacute;"		"ô"		"&ocirc;"			"õ"		"&otilde;"		"ö"		"&ouml;"
		"÷"		"&divide;"		"ø"		"&oslash;"		"ù"		"&ugrave;"		"ú"		"&uacute;"
		"û"		"&ucirc;"			"ü"		"&uuml;"			"ý"		"&yacute;"		"þ"		"&thorn;"
		"ÿ"		"&yuml;"			""		"&euro;"			"Þ"		"&THORN;"			"¿"		"&iquest;"
		""		"&oelig;"			""		"&Yuml;"			"¡"		"&iexcl;"			"ß"		"&szlig;"
		"¢"		"&cent;"			"£"		"&pound;"			"€"		"&curren;"		"¥"		"&yen;"	
		"Š"		"&brvbar;"		"Š"		"&brkbar;"		"§"		"&sect;"			"š"		"&uml;"	
		"š"		"&die;"				"©"		"&copy;"			"ª"		"&ordf;"			"«"		"&laquo;"
		"¬"		"&not;"				"®"		"&reg;"				"¯"		"&macr;"			"×"		"&times;"
		"¯"		"&hibar;"			"°"		"&deg;"				"±"		"&plusmn;"		"²"		"&sup2;"
		"³"		"&sup3;"			"Ž"		"&acute;"			"µ"		"&micro;"			"¶"		"&para;"
		"·"		"&middot;"		"ž"		"&cedil;"			"¹"		"&sup1;"			"º"		"&ordm;"
		"»"		"&raquo;"			"Œ"		"&frac14;"		"œ"		"&frac12;"		"Ÿ"		"&frac34;"
		"Æ"		"&AElig;"			"À"		"&Agrave;"		"Á"		"&Aacute;"		"Â"		"&Acirc;"
		"Ã"		"&Atilde;"		"Ä"		"&Auml;"			"Å"		"&Aring;"			"Ç"		"&Ccedil;"
		"È"		"&Egrave;"		"É"		"&Eacute;"		"Ê"		"&Ecirc;"			"Ë"		"&Euml;"
		"Ì"		"&Igrave;"		"Í"		"&Iacute;"		"Î"		"&Icirc;"			"Ñ"		"&Ntilde;"
		"Ï"		"&Iuml;"			"Ð"		"&ETH;"				"Ð"		"&Dstrok;"		"Ö"		"&Ouml;"
		"Ò"		"&Ograve;"		"Ó"		"&Oacute;"		"Ô"		"&Ocirc;"			"Õ"		"&Otilde;"
		"Ø"		"&Oslash;"		"Ù"		"&Ugrave;"		"Ú"		"&Uacute;"		"Û"		"&Ucirc;"
		"Ü"		"&Uuml;"			"Ý"		"&Yacute;"
	} $res]
	return "${res}"
}

##### Conversion des caractères html spéciaux en caractères unicode
proc ::motus::html_filter {data} {
	return [::tcl::string::map {
		"&agrave;"		"à"		"&agrave;"		"à"		"&aacute;"		"á"		"&acirc;"			"â"
		"&atilde;"		"ã"		"&auml;"			"ä"		"&aring;"			"å"		"&aelig;"			"æ"
		"&ccedil;"		"ç"		"&egrave;"		"è"		"&eacute;"		"é"		"&ecirc;"			"ê"
		"&euml;"			"ë"		"&igrave;"		"ì"		"&iacute;"		"í"		"&icirc;"			"î"
		"&iuml;"			"ï"		"&eth;"				"ð"		"&ntilde;"		"ñ"		"&ograve;"		"ò"
		"&oacute;"		"ó"		"&ocirc;"			"ô"		"&otilde;"		"õ"		"&ouml;"			"ö"
		"&divide;"		"÷"		"&oslash;"		"ø"		"&ugrave;"		"ù"		"&uacute;"		"ú"
		"&ucirc;"			"û"		"&uuml;"			"ü"		"&yacute;"		"ý"		"&thorn;"			"þ"
		"&yuml;"			"ÿ"		"&quot;"			"\""	"&amp;"				"&"		"&euro;"			""
		"&oelig;"			""		"&Yuml;"			""		"&iexcl;"			"¡"		"&lsquo;"			"'"
		"&cent;"			"¢"		"&pound;"			"£"		"&curren;"		"€"		"&yen;"				"¥"
		"&brvbar;"		"Š"		"&brkbar;"		"Š"		"&sect;"			"§"		"&uml;"				"š"
		"&die;"				"š"		"&copy;"			"©"		"&ordf;"			"ª"		"&laquo;"			"«"
		"&not;"				"¬"		"&shy;"				"­-"	"&reg;"				"®"		"&macr;"			"¯"
		"&hibar;"			"¯"		"&deg;"				"°"		"&plusmn;"		"±"		"&sup2;"			"²"
		"&sup3;"			"³"		"&acute;"			"Ž"		"&micro;"			"µ"		"&para;"			"¶"
		"&middot;"		"·"		"&cedil;"			"ž"		"&sup1;"			"¹"		"&ordm;"			"º"
		"&raquo;"			"»"		"&frac14;"		"Œ"		"&frac12;"		"œ"		"&frac34;"		"Ÿ"
		"&iquest;"		"¿"		"&Agrave;"		"À"		"&Aacute;"		"Á"		"&Acirc;"			"Â"
		"&Atilde;"		"Ã"		"&Auml;"			"Ä"		"&Aring;"			"Å"		"&AElig;"			"Æ"
		"&Ccedil;"		"Ç"		"&Egrave;"		"È"		"&Eacute;"		"É"		"&Ecirc;"			"Ê"
		"&Euml;"			"Ë"		"&Igrave;"		"Ì"		"&Iacute;"		"Í"		"&Icirc;"			"Î"
		"&Iuml;"			"Ï"		"&ETH;"				"Ð"		"&Dstrok;"		"Ð"		"&Ntilde;"		"Ñ"
		"&Ograve;"		"Ò"		"&Oacute;"		"Ó"		"&Ocirc;"			"Ô"		"&Otilde;"		"Õ"
		"&Ouml;"			"Ö"		"&times;"			"×"		"&Oslash;"		"Ø"		"&Ugrave;"		"Ù"
		"&Uacute;"		"Ú"		"&Ucirc;"			"Û"		"&Uuml;"			"Ü"		"&Yacute;"		"Ý"
		"&THORN;"			"Þ"		"&szlig;"			"ß"		"\r"					"\n"	"\t"					""
		"&#039;"			"\'"	"&#39;"				"\'"	"&nbsp;"			" "		"&nbsp"				" "
		"&#34;"				"\'"	"&#38;"				"&"		"#91;"				"\("	"&#92;"				"/"
		"&#93;"				")"		"&#123;"			"("		"&#125;"			")"		"&#163;"			"£"
		"&#168;"			"š"		"&#169;"			"©"		"&#171;"			"«"		"&#173;"			"­"
		"&#174;"			"®"		"&#180;"			"Ž"		"&#183;"			"·"		"&#185;"			"¹"
		"&#187;"			"»"		"&#188;"			"Œ"		"&#189;"			"œ"		"&#190;"			"Ÿ"
		"&#192;"			"À"		"&#193;"			"Á"		"&#194;"			"Â"		"&#195;"			"Ã"
		"&#196;"			"Ä"		"&#197;"			"Å"		"&#198;"			"Æ"		"&#199;"			"Ç"
		"&#200;"			"È"		"&#201;"			"É"		"&#202;"			"Ê"		"&#203;"			"Ë"
		"&#204;"			"Ì"		"&#205;"			"Í"		"&#206;"			"Î"		"&#207;"			"Ï"
		"&#208;"			"Ð"		"&#209;"			"Ñ"		"&#210;"			"Ò"		"&#211;"			"Ó"
		"&#212;"			"Ô"		"&#213;"			"Õ"		"&#214;"			"Ö"		"&#215;"			"×"
		"&#216;"			"Ø"		"&#217;"			"Ù"		"&#218;"			"Ú"		"&#219;"			"Û"
		"&#220;"			"Ü"		"&#221;"			"Ý"		"&#222;"			"Þ"		"&#223;"			"ß"
		"&#224;"			"à"		"&#225;"			"á"		"&#226;"			"â"		"&#227;"			"ã"
		"&#228;"			"ä"		"&#229;"			"å"		"&#230;"			"æ"		"&#231;"			"ç"
		"&#232;"			"è"		"&#233;"			"é"		"&#234;"			"ê"		"&#235;"			"ë"
		"&#236;"			"ì"		"&#237;"			"í"		"&#238;"			"î"		"&#239;"			"ï"
		"&#240;"			"ð"		"&#241;"			"ñ"		"&#242;"			"ò"		"&#243;"			"ó"
		"&#244;"			"ô"		"&#245;"			"õ"		"&#246;"			"ö"		"&#247;"			"÷"
		"&#248;"			"ø"		"&#249;"			"ù"		"&#250;"			"ú"		"&#251;"			"û"
		"&#252;"			"ü"		"&#253;"			"ý"		"&#254;"			"þ"		"&#9830;"			""
		"&lt;"				"<"		"&gt;"				">"		"&#47;"				"/"		"&#33;"				"!"
	} $data]
}

##### Coloration
proc ::motus::code {code} {
	if { !($code in {b u r s letterexists letterplaced letterexistsend letterplacedend})
		&& (($::motus::monochrome)
		|| ($code eq "")
		|| ([string match *c* [lindex [split [getchanmode $::motus::motus_chan]] 0]]))
	} then {
		return ""
	} else {
		switch -- $code {
			b { return "\002" }
			u { return "\037" }
			r { return "\026" }
			e { return "\003" }
			s { return "\017" }
			normaltext { return "\003[set ::motus::normal_text_color]" }
			specialtext1 { return "\003[set ::motus::special_text_color1]" }
			specialtext2 { return "\003[set ::motus::special_text_color2]" }
			advertise { return "\003[set ::motus::advertise_normal_color]" }
			advertise_special1 { return "\003[set ::motus::advertise_special_color1]" }
			advertise_special2 { return "\003[set ::motus::advertise_special_color2]" }
			warning { return "\003[set ::motus::warning_color]" }
			announce { return "\003[set ::motus::announce_color]" }
			announce_special { return "\003[set ::motus::announce_special_color]" }
			gimmick { return "\003[set ::motus::gimmick_color]" }
			scores { return "\003[set ::motus::scores_color]" }
			scores2 { return "\003[set ::motus::scores_color_2]" }
			scores3 { return "\003[set ::motus::scores_color_3]" }
			scores4 { return "\003[set ::motus::scores_color_4]" }
			commonletter { return "\003[set ::motus::commonletter]" }
			letterexists { if { ($::motus::monochrome != 1) && (![::tcl::string::match *c* [lindex [split [getchanmode $::motus::motus_chan]] 0]]) } { return "\003[set ::motus::letterexists]" } { return "\002" } }
			letterplaced { if { ($::motus::monochrome != 1) && (![::tcl::string::match *c* [lindex [split [getchanmode $::motus::motus_chan]] 0]]) } { return "\003[set ::motus::letterplaced]" } { return "\037\002" } }
			letterexistsend { if { ($::motus::monochrome != 1) && (![::tcl::string::match *c* [lindex [split [getchanmode $::motus::motus_chan]] 0]]) } { return "\003" } { return "\002" } }
			letterplacedend { if { ($::motus::monochrome != 1) && (![::tcl::string::match *c* [lindex [split [getchanmode $::motus::motus_chan]] 0]]) } { return "\003" } { return "\002\037" } }
			wonpoints { return "\003[set ::motus::wonpoints]" }
			lostpoints { return "\003[set ::motus::lostpoints]" }
			defcolor1 { return "\003[set ::motus::def_color_1]" }
			defcolor2 { return "\003[set ::motus::def_color_2]" }
			defcolor3 { return "\003[set ::motus::def_color_3]" }
			defcolor4 { return "\003[set ::motus::def_color_4]" }
			urlcolor { return "\003[set ::motus::urlcolor]" }
			stop { return "\003" }
			default { return "\003[set code]" }
		}
	}
}

##### Bold actif seulement si $monochrome = 0
proc ::motus::variablebold {} {
	if { ($::motus::monochrome != 1) && (![::tcl::string::match *c* [lindex [split [getchanmode $::motus::motus_chan]] 0]]) } { return "\002" }
}

##### Désallocation des ressources
proc ::motus::cleanup {} {
	::motus::cleanup_timers
	if {[::tcl::info::exists ::motus::listemots]} { unset ::motus::listemots }
	if {[::tcl::info::exists ::motus::listemotsverif]} { unset ::motus::listemotsverif }
	if {[::tcl::info::exists ::motus::proposition]} { unset ::motus::proposition }
	if {[::tcl::info::exists ::motus::motchoisi_raw]} { unset ::motus::motchoisi_raw }
	if {[::tcl::info::exists ::motus::motchoisi]} { unset ::motus::motchoisi }
	if {[array exists ::motus::dejadit]} { array unset ::motus::dejadit }
	if {[::tcl::info::exists ::motus::masque]} { unset ::motus::masque }
	if {[::tcl::info::exists ::motus::scores]} { unset ::motus::scores }
	if {[::tcl::info::exists ::motus::stats]} { unset ::motus::stats }
	if {[array exists ::motus::player_stats]} { array unset ::motus::player_stats }
	if {[::tcl::info::exists ::motus::announce_indexes]} { unset ::motus::announce_indexes }
	if {[::tcl::info::exists ::motus::current_announce_index]} { unset ::motus::current_announce_index }
	if {[::tcl::info::exists ::motus::timestart]} { unset ::motus::timestart }
	if {[::tcl::info::exists ::motus::debugtimer]} { unset ::motus::debugtimer }
	if {[::tcl::info::exists ::motus::motencoursdedebug]} { unset ::motus::motencoursdedebug }
	if {[array exists ::motus::nickchange_array]} { array unset ::motus::nickchange_array }
	set ::motus::vote_is_pending 0
	set ::motus::pending_profile_change 0
	if { [binds ::motus::check_response] ne "" } { unbind pubm -|- "$::motus::motus_chan *" ::motus::check_response }
	if { [binds ::motus::game_end] ne "" } { unbind pubm $::motus::stop_flags "$::motus::motus_chan %$::motus::stop_cmd%" ::motus::game_end }
	if { [binds ::motus::next_one] ne "" } { unbind pubm $::motus::next_flags "$::motus::motus_chan %$::motus::next_cmd%" ::motus::next_one }
	if { [binds ::motus::repete] ne "" } { unbind pubm $::motus::repeat_flags "$::motus::motus_chan %$::motus::repeat_cmd%" ::motus::repete }
	if { [binds ::motus::hint] ne "" } { unbind pubm $::motus::hint_flags "$::motus::motus_chan %$::motus::hint_cmd%" ::motus::hint }
	if { [binds ::motus::nickchange] ne "" } { unbind nick - "$::motus::motus_chan *" ::motus::nickchange }
	if { [binds ::motus::onjoin] ne "" } { unbind join -|- "$::motus::motus_chan *" ::motus::onjoin }
	if { [binds {motus::silent_stop 0}] ne "" } { unbind evnt - disconnect-server {motus::silent_stop 0} }
}

##### Arrêt des timers
proc ::motus::cleanup_timers {} {
	if {[set timetofind [motus::utimerexists {::motus::timeout}]] ne ""} { killutimer $timetofind }
	if {[set timewarning [motus::utimerexists {::motus::warning_timeout}]] ne ""} { killutimer $timewarning }
	if {[set timebetweenturns [motus::utimerexists {::motus::motsuivant}]] ne ""} { killutimer $timebetweenturns }
	if {[set timerannounce [motus::utimerexists {::motus::announce}]] ne ""} { killutimer $timerannounce }
	if {[set hinttimer [motus::utimerexists {::motus::hint - - - - auto}]] ne ""} { killutimer $hinttimer }
	if {[set debugtimer [lindex [lsearch -inline -regexp [utimers] {(.*)\ \{::motus::debugg\ (.*)}] 2]] ne ""} { killutimer $debugtimer }
	if {[set votetimer [motus::utimerexists {::motus::vote_has_ended}]] ne ""} { killutimer $votetimer }
}

 ###############################################################################
### Affichage d'un message sur le chan.
### queue peut valoir 0 (puthelp) ou 1 (putquick/putnow)
### max_lines est un entier numérique et détermine ne nombre maximum de lignes
###   à afficher (0 = aucune limite)
### La proc retourne 0 si le texte a été affiché intégralement ou 1 si le texte
###   a été tronqué en raison de la valeur de max_lines
 ###############################################################################
proc ::motus::output_public_message {queue max_lines default_color data} {
	set must_break 0
	set counter 0
	set num_lines [llength [set lines [::motus::split_line $data $::motus::max_line_length]]]
	foreach line $lines {
		if { [::tcl::string::trim $line] eq "" } { continue }
		incr counter
		if { ($counter == $max_lines) && ($counter < $num_lines) } {
			if { [::tcl::string::length $line] >= $::motus::max_line_length - 10 } {
				set line [::tcl::string::replace $line end-9 end "[code warning](...)[code stop]"]
			} else {
				append line " [code warning](...)[code stop]"
			}
			set must_break 1
		}
		if { $queue } {
			::motus::putqueue "PRIVMSG [set ::motus::motus_chan] :[code $default_color]\002\002[::tcl::string::trim [set line]][code stop]"
		} else {
			puthelp "PRIVMSG [set ::motus::motus_chan] :[code $default_color]\002\002[::tcl::string::trim [set line]][code stop]"
		}
		if { $must_break } { break }
	}
	return $must_break
}

##### Affichage d'un texte en plusieurs lignes si nécessaire afin de ne pas
##### dépasser la limite de caractères par ligne (version putlog)
proc ::motus::putlog_split_line {text} {
	set output_length [::tcl::string::length $text]
	set letter_index 0
	while { $letter_index < $output_length } {
		if { $output_length - $letter_index > 450 } {
			set cut_index [::tcl::string::last " " $text [expr $letter_index + 450]]		
		} else {
			set cut_index $output_length
		}
		lappend output [::tcl::string::range $text $letter_index $cut_index]
		set letter_index $cut_index
	}
	foreach line $output {
		putloglev o * "\00314[set line]"
	}
}

 ###############################################################################
### Découpage d'une ligne trop longue en plusieurs lignes en essayant de couper
### sur les espaces autant que possible.
### Les \n provoquent un retour à la ligne.
 ###############################################################################
proc ::motus::split_line {data {limit 1}} {
	incr limit -1
	set data [::tcl::string::trim $data]
	set data_length [::tcl::string::length $data]
	if { $data_length <= $limit } {
		return [lsearch -all -inline -not -regexp [split $data "\n"] {^([\s\003]+)?$}]
	} else {
		set cursor 0
		# Note : si l'espace le plus proche est situé à plus de 50% de la fin du
		# fragment, on n'hésite pas à couper au milieu d'un mot.
		set middle_pos [expr round($limit / 2.0)]
		while { $cursor < $data_length } {
			if { ([set cut_index [::tcl::string::first "\n" $data $cursor]] != -1)
				&& ($cut_index <= $cursor + $limit)
			} then {
				# on ne fait rien de plus, on vient de définir $cut_index
			} elseif { ([set cut_index [::tcl::string::last " " $data [expr {$cursor + $limit + 1}]]] == -1)
				|| ($cut_index <= $cursor)
				|| ($data_length - $cursor < $limit)
				|| ($cut_index - $cursor < $middle_pos)
			} then {
				set cut_index [expr {$cursor + $limit}]
			}
			lappend output [::tcl::string::trimright [::tcl::string::range $data $cursor $cut_index]]
			set cursor [expr {$cut_index + 1}]
		}
		return [lsearch -all -inline -not -regexp $output {^([\s\003]+)?$}]
	}
}

##### Queue serveur rapide (si l'option alternate_msg_queue est activée)
proc ::motus::putqueue {data} {
	if { $::motus::alternate_msg_queue } {
		putnow $data
	} else {
		putquick $data
	}
	return
}

##### Mise en ordre aléatoire d'une liste
proc ::motus::lrandomize {data} {
	set list_length [llength $data]
	for { set counter 1 } { $counter <= $list_length } { incr counter } {
		set index [rand [expr $list_length - $counter + 1]]
		lappend randomized_list [lindex $data $index]
		set data [lreplace $data $index $index]
	}
	return $randomized_list
}

##### Vérification si un fichier est accessible en lecture
proc ::motus::is_readable {file silent} {
	if { [file readable $file] } {
		return 1
	} else {
		if { !$silent } { puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code stop][code normaltext]Le fichier[code stop][code specialtext1] $file [code stop][code normaltext]n'est pas accessible en lecture. Veuillez vérifier les autorisations.[code stop]" }
		putloglev o * "\00304\002\[Motus - erreur\]\002\003 : \00314Le fichier\003 $file \00314n'est pas accessible en lecture. Veuillez vérifier les autorisations.\003"
		return 0
	}
}

##### Vérification si un fichier est accessible en écriture
proc ::motus::is_writable {file silent} {
	if { [file writable $file] } {
		return 1
	} else {
		if { !$silent } { puthelp "PRIVMSG $::motus::motus_chan :[code warning]\037Erreur\037 : [code stop][code normaltext]Le fichier[code stop][code specialtext1] $file [code stop][code normaltext]n'est pas accessible en écriture. Veuillez vérifier les autorisations.[code stop]" }
		putloglev o * "\00304\002\[Motus - erreur\]\002\003 : \00314Le fichier\003 $file \00314n'est pas accessible en écriture. Veuillez vérifier les autorisations.\003"
		return 0
	}
}

##### Contournement bug Eggdrop 1.8.x : https://github.com/eggheads/eggdrop/issues/815
proc ::motus::matchattr_ {hand flags {chan {}}} {
	if {
		($flags eq "-")
		|| ($flags eq "-|-")
		|| [matchattr $hand $flags $chan]
	} then {
		return 1
	} else {
		return 0
	}
}

##### Conversion de l'URL en une version plus courte
proc ::motus::tinyurl_conversion {url} {
  set url [::tcl::string::map -nocase {
	  "&amp;"		"&"
  } $url]
	set query "http://tinyurl.com/api-create.php?[::http::formatQuery url ${url}]"
	http::config -useragent $::motus::useragent
	set token [http::geturl $query -timeout [expr $::motus::tinyurl_timeout * 1000]]
	set link [http::data $token]
	::http::cleanup $token
	if {($link != 0) && ($link ne "")} {
		return $link
	} {
		return "${url}"
	}
}

##### Procédure anti-freeze (normalement inutile, mais présente au cas où)
proc ::motus::debugg {ancien_mot} {
	if { ($::motus::status >= 1) || ($ancien_mot == 0)} {
		set motcompare $::motus::motencoursdedebug
		if { $ancien_mot eq $motcompare } {
			putloglev o * "\00304\002\[Motus - erreur\]\002\003 Le Motus semble être bloqué. Réinitialisation du jeu..."
			if {[set timebetweenturns [::motus::utimerexists {::motus::motsuivant}]] ne ""} { killutimer $timebetweenturns }
			if {[set timetofind [::motus::utimerexists {::motus::timeout}]] ne ""} { killutimer $timetofind }
			if {[set timewarning [::motus::utimerexists {::motus::warning_timeout}]] ne ""} { killutimer $timewarning }
			if {[set hinttimer [::motus::utimerexists {::motus::hint - - - - auto}]] ne ""} { killutimer $hinttimer }
			if {[set timerannounce [::motus::utimerexists {::motus::announce}]] ne ""} { killutimer $timerannounce }
			::motus::putqueue "PRIVMSG $::motus::motus_chan :[code warning]\002Il semble que le jeu soit bloqué, relancement automatique.\002[code stop]"
			variable debugtimer [utimer [expr $::motus::round_time + $::motus::pause_time + 30] "::motus::debugg $motcompare"]
			::motus::motsuivant
		} else {
			variable debugtimer [utimer [expr $::motus::round_time + $::motus::pause_time + 30] "::motus::debugg $motcompare"]
		} 
	} else {
		if { [::tcl::info::exists ::motus::motencoursdedebug] } { unset ::motus::motencoursdedebug }
	}
}

##### Retourne une liste des chans sur lesquels l'Eggdrop se trouve.
proc ::motus::joined_chans {} {
	set joined_chans {}
	foreach chan [channels] {
		if [botonchan $chan] { lappend joined_chans $chan }
	}
	return $joined_chans
}

##### Génération d'un rapport de déboguage
proc ::motus::debug_report {filename auto} {
	if {[::tcl::info::exists ::errorInfo]} {set last_error $::errorInfo} {set last_error "aucune"}
	set binds_list [lsearch -all -inline [binds] "*motus::*"]
	set scriptfile [open $::motus_script_file r]
	set scriptmd5checksum [md5 [read -nonewline $scriptfile]]
	close $scriptfile
	set output [list \
		"======= $::motus::scriptname v$::motus::version - Rapport de déboguage =======" \
		"======= généré [strftime "le %d/%m/%Y à %H:%M:%S" [unixtime]]" \
		" " \
		"dernière erreur : $last_error" \
		" " \
		"------- Environnement" \
		"version Eggdrop : [if {[::tcl::info::sharedlibextension] eq ".dll"} {set eggtype "Windrop"} {set eggtype "Eggdrop"}] $::version" \
		"version Tcl : [::tcl::info::tclversion] ([::tcl::info::library])" \
		"Tcl patchlevel : [::tcl::info::patchlevel]" \
		"packages installés : [package names]" \
		"version package http : [if {[lsearch [package names] "http"] != -1} { package present http } else { set dummy "pas détecté" }]" \
		"nom du bot : $::botnick" \
		"bind tcl : [if {[binds tcl] ne ""} {binds tcl} {set dummy "non défini"}]" \
		"bind set : [if {[binds set] ne ""} {binds set} {set dummy "non défini"}]" \
		"serveur : $::server" \
		"canaux actifs : [::motus::joined_chans]" \
		"namespace : [namespace current]" \
		"Motus udef sur motus_chan : [channel get $::motus::motus_chan motus]" \
		"bot op sur motus_chan : [isop $::botnick $::motus::motus_chan]" \
		"emplacement de motus.tcl : $::motus_script_file" \
		"taille de motus.tcl : [file size $::motus_script_file] octets" \
		"checksum MD5 de motus.tcl : $scriptmd5checksum" \
		" " \
		"------- Etat du jeu" \
		"état du jeu : [if {![::tcl::info::exists ::motus::status]} { set dummy "non défini" } elseif {$::motus::status == 0} { set dummy "stoppé" } elseif {$::motus::status == 1} { set dummy "partie en cours - round en cours" } elseif { $::motus::status == 2 } { set dummy "partie en cours - inter-round" } else { set dummy "état inconnu : ($::motus::status)" }]" \
		"pending_profile_change : $::motus::pending_profile_change" \
		"special_queue_running : $::motus::special_queue_running" \
		" " \
		"------- Binds actifs" \
		"[join $binds_list "\n"]" \
		" " \
		"------- Timers actifs" \
		"[join [lsearch -all -inline [timers] "*::motus::*"] "\n"]" \
		" " \
		"------- Utimers actifs" \
		"[join [lsearch -all -inline [utimers] "*::motus::*"] "\n"]" \
		" " \
		"------- Variables de configuration" \
		"config_path : $::motus::config_path" \
		"main_config_file : $::motus::main_config_file ([file exists $::motus::main_config_file_full])" \
		"profile_file : $::motus::profile_file ([file exists $::motus::profile_file_full])" \
		"profile_description : $::motus::profile_description" \
		"motus_chan : $::motus::motus_chan" \
		"players_can_change_profile : $::motus::players_can_change_profile" \
		"profiles_selectable_by_users : $::motus::profiles_selectable_by_users" \
		"restore_default_profile_at_game_end : $::motus::restore_default_profile_at_game_end" \
		"show_profile_description : $::motus::show_profile_description" \
		"voice_players : $::motus::voice_players" \
		"voice_staff : $::motus::voice_staff" \
		"help_mode : [if {[set ::motus::help_mode]} {set dummy "PRIVMSG"} {set dummy "NOTICE"}]" \
		"advertise : $::motus::advertise" \
		"advertise_targets : $::motus::advertise_targets" \
		"achievements_enabled : $::motus::achievements_enabled" \
		"max_line_length : $::motus::max_line_length" \
		"findplayer_max_results : $::motus::findplayer_max_results" \
		"warn_on_fusion : $::motus::warn_on_fusion" \
		"daily_backup : $::motus::daily_backup" \
		"alternate_msg_queue : $::motus::alternate_msg_queue" \
		"public_debug_info : $::motus::public_debug_info" \
		"auto_generate_debug_report : $::motus::auto_generate_debug_report" \
		"auto_debug_report_file : $::motus::auto_debug_report_file ([file exists $::motus::auto_debug_report_file])" \
		"round_time : $::motus::round_time" \
		"pause_time : $::motus::pause_time" \
		"announce_delay : $::motus::announce_delay" \
		"idle_auto_stop : $::motus::idle_auto_stop" \
		"definition_timeout : $::motus::definition_timeout" \
		"tinyurl_timeout : $::motus::tinyurl_timeout" \
		"player_cooldown_time : $::motus::player_cooldown_time" \
		"vote_time : $::motus::vote_time" \
		"change_lock_time : $::motus::change_lock_time" \
		"min_word_length : $::motus::min_word_length" \
		"max_word_length : $::motus::max_word_length" \
		"wordlength_weight(4) : $::motus::wordlength_weight(4) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(4)] } {set dummy "-> $::motus::computed_wordlength_weight(4)"}]" \
		"wordlength_weight(5) : $::motus::wordlength_weight(5) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(5)] } {set dummy "-> $::motus::computed_wordlength_weight(5)"}]" \
		"wordlength_weight(6) : $::motus::wordlength_weight(6) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(6)] } {set dummy "-> $::motus::computed_wordlength_weight(6)"}]" \
		"wordlength_weight(7) : $::motus::wordlength_weight(7) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(7)] } {set dummy "-> $::motus::computed_wordlength_weight(7)"}]" \
		"wordlength_weight(8) : $::motus::wordlength_weight(8) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(8)] } {set dummy "-> $::motus::computed_wordlength_weight(8)"}]" \
		"wordlength_weight(9) : $::motus::wordlength_weight(9) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(9)] } {set dummy "-> $::motus::computed_wordlength_weight(9)"}]" \
		"wordlength_weight(10) : $::motus::wordlength_weight(10) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(10)] } {set dummy "-> $::motus::computed_wordlength_weight(10)"}]" \
		"wordlength_weight(11) : $::motus::wordlength_weight(11) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(11)] } {set dummy "-> $::motus::computed_wordlength_weight(11)"}]" \
		"wordlength_weight(12) : $::motus::wordlength_weight(12) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(12)] } {set dummy "-> $::motus::computed_wordlength_weight(12)"}]" \
		"wordlength_weight(13) : $::motus::wordlength_weight(13) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(13)] } {set dummy "-> $::motus::computed_wordlength_weight(13)"}]" \
		"wordlength_weight(14) : $::motus::wordlength_weight(14) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(14)] } {set dummy "-> $::motus::computed_wordlength_weight(14)"}]" \
		"wordlength_weight(15) : $::motus::wordlength_weight(15) [if { [::tcl::info::exists ::motus::computed_wordlength_weight(15)] } {set dummy "-> $::motus::computed_wordlength_weight(15)"}]" \
		"auto_hint_mode : $::motus::auto_hint_mode" \
		"hint_time : $::motus::hint_time" \
		"max_hints : $::motus::max_hints" \
		"give_last_hint : $::motus::give_last_hint" \
		"placed_hints(4) : $::motus::placed_hints(4)" \
		"placed_hints(5) : $::motus::placed_hints(5)" \
		"placed_hints(6) : $::motus::placed_hints(6)" \
		"placed_hints(7) : $::motus::placed_hints(7)" \
		"placed_hints(8) : $::motus::placed_hints(8)" \
		"placed_hints(9) : $::motus::placed_hints(9)" \
		"placed_hints(10) : $::motus::placed_hints(10)" \
		"placed_hints(11) : $::motus::placed_hints(11)" \
		"placed_hints(12) : $::motus::placed_hints(12)" \
		"placed_hints(13) : $::motus::placed_hints(13)" \
		"placed_hints(14) : $::motus::placed_hints(14)" \
		"placed_hints(15) : $::motus::placed_hints(15)" \
		"define_words : $::motus::define_words" \
		"definitions_max_lines : $::motus::definitions_max_lines" \
		"show_definition_link : $::motus::show_definition_link" \
		"shorten_URLs : $::motus::shorten_URLs" \
		"pts_letter_found : $::motus::pts_letter_found" \
		"pts_letter_placed : $::motus::pts_letter_placed" \
		"pts_word_found : $::motus::pts_word_found" \
		"speed_reward : $::motus::speed_reward" \
		"speed_bonus_10 : $::motus::speed_bonus_10" \
		"speed_bonus_20 : $::motus::speed_bonus_20" \
		"speed_bonus_35 : $::motus::speed_bonus_35" \
		"speed_bonus_50 : $::motus::speed_bonus_50" \
		"lose_points : $::motus::lose_points" \
		"said_lost_points : $::motus::said_lost_points" \
		"inexistant_lost_points : $::motus::inexistant_lost_points" \
		"null_lost_points : $::motus::null_lost_points" \
		"clearscoresweekly : $::motus::clearscoresweekly" \
		"clearscores_day : $::motus::clearscores_day" \
		"clearscores_time : $::motus::clearscores_time" \
		"html_export : $::motus::html_export" \
		"html_export_interval : $::motus::html_export_interval" \
		"html_footer1 : $::motus::html_footer1" \
		"html_footer2 : $::motus::html_footer2" \
		"announces : $::motus::announces" \
		"announce_freq : $::motus::announce_freq" \
		"announce_statements : $::motus::announce_statements" \
		"monochrome : $::motus::monochrome" \
		"normal_text_color : $::motus::normal_text_color" \
		"special_text_color1 : $::motus::special_text_color1" \
		"special_text_color2 : $::motus::special_text_color2" \
		"advertise_normal_color : $::motus::advertise_normal_color" \
		"advertise_special_color1 : $::motus::advertise_special_color1" \
		"advertise_special_color2 : $::motus::advertise_special_color2" \
		"warning_color : $::motus::warning_color" \
		"announce_color : $::motus::announce_color" \
		"announce_special_color : $::motus::announce_special_color" \
		"gimmick_color : $::motus::gimmick_color" \
		"scores_color : $::motus::scores_color" \
		"scores_color_2 : $::motus::scores_color_2" \
		"scores_color_3 : $::motus::scores_color_3" \
		"scores_color_4 : $::motus::scores_color_4" \
		"letterplaced : $::motus::letterplaced" \
		"letterexists : $::motus::letterexists" \
		"commonletter : $::motus::commonletter" \
		"wonpoints : $::motus::wonpoints" \
		"lostpoints : $::motus::lostpoints" \
		"def_color_1 : $::motus::def_color_1" \
		"def_color_2 : $::motus::def_color_2" \
		"def_color_3 : $::motus::def_color_3" \
		"def_color_4 : $::motus::def_color_4" \
		"urlcolor : $::motus::urlcolor" \
		"admin_flags : $::motus::admin_flags" \
		"start_cmd : $::motus::start_cmd" \
		"start_flags : $::motus::start_flags" \
		"stop_cmd : $::motus::stop_cmd" \
		"stop_flags : $::motus::stop_flags" \
		"help_cmd : $::motus::help_cmd" \
		"help_flags : $::motus::help_flags" \
		"scores_cmd : $::motus::scores_cmd" \
		"scores_flags : $::motus::scores_flags" \
		"score_cmd : $::motus::score_cmd" \
		"score_flags : $::motus::score_flags" \
		"place_cmd : $::motus::place_cmd" \
		"place_flags : $::motus::place_flags" \
		"stat_cmd : $::motus::stat_cmd" \
		"stat_flags : $::motus::stat_flags" \
		"records_cmd : $::motus::records_cmd" \
		"records_flags : $::motus::records_flags" \
		"findplayers_cmd : $::motus::findplayers_cmd" \
		"findplayers_flags : $::motus::findplayers_flags" \
		"playersfusion_cmd : $::motus::playersfusion_cmd" \
		"playersfusion_flags : $::motus::playersfusion_flags" \
		"playerrename_cmd : $::motus::playerrename_cmd" \
		"playerrename_flags : $::motus::playerrename_flags" \
		"clearscores_cmd : $::motus::clearscores_cmd" \
		"clearscores_flags : $::motus::clearscores_flags" \
		"resetstats_cmd : $::motus::resetstats_cmd" \
		"resetstats_flags : $::motus::resetstats_flags" \
		"htmlupdate_cmd : $::motus::htmlupdate_cmd" \
		"htmlupdate_flags : $::motus::htmlupdate_flags" \
		"repeat_cmd : $::motus::repeat_cmd" \
		"repeat_flags : $::motus::repeat_flags" \
		"next_cmd : $::motus::next_cmd" \
		"next_flags : $::motus::next_flags" \
		"hint_cmd : $::motus::hint_cmd" \
		"hint_flags : $::motus::hint_flags" \
		"config_cmd : $::motus::config_cmd" \
		"config_flags : $::motus::config_flags" \
		"profile_change_cmd : $::motus::profile_change_cmd" \
		"profile_change_flags : $::motus::profile_change_flags" \
		"profile_voting_cmd : $::motus::profile_voting_cmd" \
		"profile_voting_flags : $::motus::profile_voting_flags" \
		"selectable_profiles_list_cmd : $::motus::selectable_profiles_list_cmd" \
		"selectable_profiles_list_flags : $::motus::selectable_profiles_list_flags" \
		"wordlist_file : $::motus::wordlist_file ([if { [file exists $::motus::wordlist_file] } { set wordlistfile [open $::motus::wordlist_file r] ; set wordlistmd5checksum [md5 [read -nonewline $wordlistfile]] ; close $wordlistfile ; set dummy "[file size $::motus::wordlist_file] octets / $wordlistmd5checksum" } else { set dummy "fichier manquant" }])" \
		"dictionary_file : $::motus::dictionary_file ([if { [file exists $::motus::dictionary_file] } { set dictionaryfile [open $::motus::dictionary_file r] ; set dictionarymd5checksum [md5 [read -nonewline $dictionaryfile]] ; close $dictionaryfile ; set dummy "[file size $::motus::dictionary_file] octets / $dictionarymd5checksum" } else { set dummy "fichier manquant" }])" \
		"scores_file : $::motus::scores_file ([file exists $::motus::scores_file])" \
		"scores_file converti : [set ::motus::scores_file].old ([file exists "[set ::motus::scores_file].old"])" \
		"scores_archive_file : $::motus::scores_archive_file ([file exists $::motus::scores_archive_file])" \
		"scores_archive_file converti : [set ::motus::scores_archive_file].old ([file exists "[set ::motus::scores_archive_file].old"])" \
		"stats_file : $::motus::stats_file ([file exists $::motus::stats_file])" \
		"stats_file converti : [set ::motus::stats_file].old ([file exists "[set ::motus::stats_file].old"])" \
		"playerstats_file : $::motus::playerstats_file ([file exists $::motus::playerstats_file])" \
		"playerstats_file converti : [set ::motus::playerstats_file].old ([file exists "[set ::motus::playerstats_file].old"])" \
		"champ_file (obsolète) : $::motus::champ_file ([file exists $::motus::champ_file])" \
		"champ_file converti (obsolète) : [set ::motus::champ_file].old ([file exists "[set ::motus::champ_file].old"])" \
		"finder_file (obsolète) : $::motus::finder_file ([file exists $::motus::finder_file])" \
		"finder_file converti (obsolète) : [set ::motus::finder_file].old ([file exists "[set ::motus::finder_file].old"])" \
		"html_export_path : $::motus::html_export_path ([file exists $::motus::html_export_path])" \
		"html_filename (fichier HTML généré) : $::motus::html_filename ([file exists "[set ::motus::html_export_path][set ::motus::html_filename]"])" \
		"css_filename (fichier CSS généré) : $::motus::css_filename ([file exists "[set ::motus::html_export_path][set ::motus::css_filename]"])" \
		"html_template_path : $::motus::html_template_path ([file exists $::motus::html_template_path])" \
		"fichier template HTML : index.html ([file exists "[set ::motus::html_template_path]index.html"])" \
		"fichier template HTML : style.css ([file exists "[set ::motus::html_template_path]style.css"])" \
	]
	if { ([::tcl::info::exists $filename]) && (![motus::is_writable $filename 1]) } { file delete -force $filename }
	set fichierreport [open $filename w]
	puts $fichierreport [join $output "\n"]
	close $fichierreport
	if { !$auto } {
		set message "[code warning]\002\[Motus - info\]\002[code stop] Un rapport de déboguage nommé motus_report.txt a été créé dans le répertoire de l'eggdrop."
		puthelp "PRIVMSG $::motus::motus_chan :$message"
	} else {
		set message "[code warning]\002\[Motus - info\]\002[code stop] Un rapport de déboguage automatique a été créé ([set filename])"
	}
	putloglev o * "$message"
	return
}

putlog "$::motus::scriptname v$::motus::version (©2005-2020 Menz Agitat) a été chargé"
