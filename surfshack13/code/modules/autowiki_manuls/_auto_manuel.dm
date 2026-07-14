#define GENERATED_WIKI_PATH "surfshack13/frogui/generated/"
/proc/setup_other_autowiki()
	Master.sleep_offline_after_initializations = FALSE
	SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(run_other_autowiki)))
	SSticker.start_immediately = TRUE
	CONFIG_SET(number/round_end_countdown, 0)

/proc/run_other_autowiki()
	var/list/autowikis = subtypesof(/datum/other_autowiki)
	for(var/wiki_type as anything in autowikis)
		var/datum/other_autowiki/wiki = new wiki_type()
		if(!wiki.file_name)
			CRASH("autowiki [wiki.type]  has no file output name")
		var/output = wiki.generate()
		if(!output)
			CRASH("autowiki [wiki.type] produced no output and appears broken.")
		rustg_file_write(output, GENERATED_WIKI_PATH + wiki.file_name)
		qdel(wiki)
	qdel(world)

/datum/other_autowiki
	///the html template which info is inserted in
	var/html_template
	///the name where the wiki should be saved to.
	var/file_name

/datum/other_autowiki/proc/generate()
	return

/datum/other_autowiki/emag_description
	html_template = \
	{"<!DOCTYPE html>
	<html lang="en">
	<!-- auto generated -->
	<head>
		<meta http-equiv='X-UA-Compatible' content='IE=edge'>
		<meta charset='utf-8'>
		<link rel='stylesheet' href='ui.css'>
	</head>
	<body>
		<div class=' wiki'>
			<div class='Section__title'><span class='Section__titleText'>Cryptographic Sequencer</span></div>
			<span>The Cryptographic Sequencer (or Emag) can be used to hack or break open a variety of differnt
				machines. It usually causes adverse and dangerous behaviors.</span>
		</div>
		<div class=' wiki'>
			<div class='Section__title'><span class='Section__titleText'>Hackable objects</span></div>
			<span>Use ctrl + f to quickly search the table.</span>
			<table class="ref_table">
				<thead>
					<th>Name</th>
					<th>Description</th>
					<th>Emag Effects</th>
				</thead>
				<tbody>
	<!-- manuel insert tag -->
			</tbody>
		</table>
	</body>
	</html>"}
	file_name = "emag_descriptions.html"

/datum/other_autowiki/emag_description/generate()
	var/filling = ""
	for(var/datum/wiki_data/wiki as anything in subtypesof(/datum/wiki_data))
		if(!wiki.emag_description || !wiki.atom_template)
			continue
		var/atom/A =  wiki.atom_template
		var/name = wiki.entry_name ? wiki.entry_name : A.name
		name = capitalize(format_text(name))
		if(!name)
			CRASH("no name found for [wiki.type]")
		var/desc = wiki.entry_desc ? wiki.entry_desc : A.desc
		desc = capitalize(desc)
		if(!desc)
			CRASH("no description found for [wiki.type]")
		filling += "\t\t\t\t<tr><th>[name]</th><td>[desc]</td><td>[wiki.emag_description]</td></tr>\n"
	. = replacetext(html_template , "<!-- manuel insert tag -->", filling)

/datum/wiki_data
	///the atom to get attributes from, like the image and name.
	var/atom_template
	/// the name in the auto wiki, if left blank pulled from atom_template
	var/entry_name
	/// the description of the atom, if left blank pulled from atom_template
	var/entry_desc
	/// if the atom is emagable, what it does.
	var/emag_description
