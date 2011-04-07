function postMessage() {
	var personalized_message = $("personalized_message");
	var from_form = $("invitation_personalized_message");
	personalized_message.innerHTML = from_form.value.replace(/\n/g, "<br/>") + " ";
}

function validEmail(email) {
	var filter  = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	return filter.test(email);
}

function verifyInput() {
	form = document.forms[0]
	form.deliverButton.disabled = true;

	var instructions  = "Please complete the form.";
	var has_recipient = false;

	var personalized_message  = $("invitation_personalized_message");
	var sender_email  = form.invitation_sender_email;
	var sender_name   = form.invitation_sender_name;

	for( var i = 0; i < form.invitation_recipient_email.length; i++ )
		if (validEmail(form.invitation_recipient_email[i].value))
			has_recipient = true;

	var has_sender    = sender_email.value.length > 0 && sender_name.value.length > 0;
	var has_message   = personalized_message.value.length > 0;
	var invalid_email = false;

	for( var i = 0; i < form.invitation_recipient_email.length; i++ )
		if (form.invitation_recipient_email[i].value.length > 0 && !validEmail(form.invitation_recipient_email[i].value))
			invalid_email = true;

	if(!validEmail(sender_email.value))
		invalid_email = true;

	if (!has_sender)
		instructions = "Please enter your complete sender information.";
	else if (!has_message)
		instructions = "Please enter the message.";
	else if (!has_recipient)
		instructions = "Please add at least one recipient.";
	else if (invalid_email)
		instructions = "One of the emails in invalid.";
	else
	{
		instructions = "You may now deliver your invitation.";
		form.deliverButton.disabled = false;
	}
	$("instructions").innerHTML = instructions;
}
