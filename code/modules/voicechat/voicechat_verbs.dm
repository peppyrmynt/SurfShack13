
/mob/verb/join_vc()
	if(!SSvoicechat || !SSvoicechat.initialized)
		to_chat(src, span_ooc("voicechat either not initialized yet, broken, or turned off"))
		return
	src << browse({"
	<html>
	<h2>Experimental Proximity Chat)</h2>
	<p>if the browser fails to open try "join vc external" instead</p>
	<p>This command should open an external broswer.<br>
	1. ignore the bad cert and continue onto the site.<br>
	2. When prompted, allow mic perms and then you should be set up.<br>
	3. To verify this is working, look for a speaker overlay over your mob in-game.</p>
	4. drag the voicechat to its own window so its only the active tab - why? if you open a different tab it stops detecting microphone input. The easiest way to ensure the tab is active, is to drag it to its own window.
	<h4>other verbs</h4>
	<p>mute - mutes yourself<br>
	deafen - deafens yourself<br>
	<h4>issues</h4>
	<p>To try to solve yourself, ensure browser extensions are off and if you are comfortable with it, turn off your VPN.
	Additionally try setting firefox as your default browser as that usually works best</p>
	<h4>reporting bugs</h4>
	<p> If your are still having issues, its most likely with rtc connections, (roughly 10% connections fail). When reporting bugs, please tell us what OS and browser you are using, if you use a VPN, and send a screenshot of your browser console to us (ctrl + shift + I).
	Additionally I might ask you to navigate to about:webrtc</p>
	<h4>But Im to lazy to report a bug</h4>
	<p>contact a_forg on discord and they might not ignore you.</p>
	<img src='https://files.catbox.moe/mkz9tv.png>
	</html>"}, "window=voicechat_help")


	SSvoicechat.join_vc(client)

/mob/verb/join_vc_external()
	if(!SSvoicechat || !SSvoicechat.initialized)
		to_chat(src, span_ooc("voicechat either not initialized yet, broken, or turned off"))
		return

	if(SSvoicechat)
		SSvoicechat.join_vc(client, show_link_only=TRUE)


/mob/verb/mute_self()
	if(SSvoicechat)
		SSvoicechat.mute_mic(client)


/mob/verb/deafen()
	if(SSvoicechat)
		SSvoicechat.mute_mic(client, deafen=TRUE)
