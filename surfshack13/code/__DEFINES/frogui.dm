#define FROGUI_USE_CHECK var/mob/user = usr; if(!user) {CRASH("ui user not found")} if(!user.can_perform_action(src, NEED_LITERACY|NEED_DEXTERITY|NEED_HANDS|FORBID_TELEKINESIS_REACH)) { SSfrogui.close_ui(user, src); return}
// var/mob/user = usr
// 	if(!user)
// 		CRASH("ui user not found")
// 	if(!user.can_perform_action(src, NEED_LITERACY|NEED_DEXTERITY|NEED_HANDS|FORBID_TELEKINESIS_REACH))
// 		SSfrogui.close_ui(user, src)
// 		return

