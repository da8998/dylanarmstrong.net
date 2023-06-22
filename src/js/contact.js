function submitToAPI(e) {
    e.preventDefault();

    var email = $("#email").val();
    var subject = $("#subject").val();
    var message = $("#message").val();
    var data = {
        email : email,
        subject : subject,
        message : message,
     };
     if(email != "" && subject != "" && message != "") {
      if(email.includes("robyn") || email.includes("moody") || email.includes("mum")) {
        alert("Quit stalking. This has been recorded.");
       }
       else {
        alert('Email has been sent. I will get back to you soon!');
       }
       $.ajax({
        type: "POST",
        url : "https://ewy0x4hiwe.execute-api.ap-southeast-2.amazonaws.com/dev/Email",
        dataType: "json",
        crossDomain: "true",
        data: JSON.stringify(data),
      });
     }
     else {
      alert("Please check the form details you entered and try again.")
  }
}