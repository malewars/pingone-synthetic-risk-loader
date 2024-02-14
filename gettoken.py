#!/opt/homebrew/bin/python3
import base64, requests, sys

print ('argument list', sys.argv)

client_id = sys.argv[1] 
client_secret = sys.argv[2]
envid = sys.argv[3]
#client_id = "c61b30db-bb85-47cb-8b26-5ac61749c0ad"
#client_secret = "lDc8pG8sTnR8rZej03FR5-JxmYFnp0GH06ta1htI0yuj.UyuJ~c8d6Wy5nHlHU1X"

# Encode the client ID and client secret
authorization = base64.b64encode(bytes(client_id + ":" + client_secret, "ISO-8859-1")).decode("ascii")


headers = {
    "Authorization": f"Basic {authorization}",
    "Content-Type": "application/x-www-form-urlencoded"
}
body = {
    "grant_type": "client_credentials"
}

#response = requests.post("https://auth.pingone.com/b3ca8a0e-8c00-49ba-8f26-69698ac893db/as/token", data=body, headers=headers)
response = requests.post("https://auth.pingone.com/{}/as/token".format(envid),data=body, headers=headers)

print(response.text)
