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
	form.commit.disabled = true;

	var instructions  = "Please complete the form.";
	var personalized_message  = $("invitation_personalized_message");
	var sender_email  = form.invitation_sender_email;
	var sender_name   = form.invitation_sender_name;
	var recipients    = form.invitation_recipient_email.value.split(";");
	var has_recipient = false;
	var has_sender    = sender_email.value.length > 0 && sender_name.value.length > 0;
	var has_message   = personalized_message.value.length > 0;
	var invalid_email = false;

	if(!validEmail(sender_email.value))
		invalid_email = true;

	for( var i = 0; i < recipients.length; i++ )
	{
		recipients[i] = recipients[i].replace(/^\s+|\s+$/g, '') ;
		if (validEmail(recipients[i]))
			has_recipient = true;
		else if (recipients[i].length > 0)
			invalid_email = true;
	}

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
		form.commit.disabled = false;
	}

	$("instructions").innerHTML = instructions;
}

function initializeForm() {
 	verifyInput();
	postMessage();
}

Event.observe(window, 'load', initializeForm, false);
