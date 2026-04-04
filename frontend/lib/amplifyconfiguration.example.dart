// Copy this file to amplifyconfiguration.dart and fill in your real values.
// amplifyconfiguration.dart is gitignored — never commit it.
const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/0.1.0",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "YOUR_USER_POOL_ID",
                        "AppClientId": "YOUR_APP_CLIENT_ID",
                        "Region": "YOUR_REGION"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "loginWith": {
                            "email": true
                        }
                    }
                }
            }
        }
    }
}''';
