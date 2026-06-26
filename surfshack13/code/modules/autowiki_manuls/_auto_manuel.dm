/proc/generate_autowikiii()
	var/template = \
{"<!DOCTYPE html>
<html lang="en">
<head>
	<meta http-equiv='X-UA-Compatible' content='IE=edge'>
	<meta charset='utf-8'>
	<link rel='stylesheet' href='ui.css'>
</head>
<body>
	<table class="ref_table">
		<thead>
			<th>Name</th>
			<th>Description</th>
			<th>Emag Effects.</th>
		</thead>
		<tbody>
<!-- manuel insert tag -->
		</tbody>
	</table>
</body>
</html>"}
	var/filling = ""
	for(var/datum/wiki_data/wiki as anything in subtypesof(/datum/wiki_data))
		if(!wiki.emag_description || !wiki.atom_template)
			continue
		var/atom/A =  wiki.atom_template
		var/name = wiki.name | A.name
		name = capitalize(format_text(name))
		if(!name)
			CRASH("no name found for [wiki.type]")
		var/desc = wiki.desc | A.desc
		desc = capitalize(desc)
		if(!desc)
			CRASH("no description found for [wiki.type]")
		filling += "\t\t\t\t<tr><th>[name]</th><td>[desc]</td><td>[wiki.emag_description]</td></tr>\n"
	var/output = replacetext(template , "<!-- manuel insert tag -->", filling)
	rustg_file_write(output, "emag_manuel.html")
	message_admins("done")

/datum/wiki_data
	///the atom to get attributes from, like the image and name.
	var/atom_template
	/// the name in the auto wiki, if left blank pulled from atom_template
	var/name
	/// the description of the atom, if left blank pulled from atom_template
	var/desc
	/// if the atom is emagable, what it does.
	var/emag_description
