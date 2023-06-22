const AWS = require('aws-sdk');
const sesClient = new AWS.SES();
const sesConfirmedAddress = "dylan.r.armstrong@outlook.com";

exports.handler = (event, context, callback) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    const request = JSON.parse(event.body);
    const params = getEmailMessage(request);
    const sendEmailPromise = sesClient.sendEmail(params).promise();
    
        const response = {
            statusCode: 200,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type'
            }
        };
    
        sendEmailPromise.then(function(result) {
            console.log(result);
            callback(null, response);
        }).catch(function(err) {
            console.log(err);
            response.statusCode = 500;
            callback(null, response);
    });
};

function getEmailMessage (request) {
    
        var emailRequestParams = {
            Destination: {
                ToAddresses: [ sesConfirmedAddress ]  
            },
            Message: {
                Body: {
                    Text: {
                        Data: request.message
                    }
                },
                Subject: {
                    Data: request.subject
                }
            },
            Source: sesConfirmedAddress,
            ReplyToAddresses: [ request.email ]
        };
    return emailRequestParams;
}