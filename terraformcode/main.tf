provider "random" {}

data "external" "read_credentials" {
   program = ["cat", "credentials.json"]
}

locals {
 client = join(":",[data.external.read_credentials.result.client_id],[data.external.read_credentials.result.client_secret])
 encodedclient = base64encode(local.client)
}

variable "token_rotation_interval" {
   description = "Number of runs before token rotation"
   type        = number
   default     = 10
}

resource "random_integer" "random_ip" {
   min = 1
   max = 255
}
resource "random_integer" "random_ip2" {
   min = 1
   max = 255
}
resource "random_integer" "random_ip3" {
   min = 1
   max = 255
}
resource "random_integer" "random_ip4" {
   min = 1
   max = 255
}

locals {
 ip_address = format("%d.%d.%d.%d", random_integer.random_ip.result, random_integer.random_ip2.result,random_integer.random_ip3.result,random_integer.random_ip4.result)
}

resource "null_resource" "get_token" {

   provisioner "local-exec" {
     command = <<EOT
mytoken=$(curl -s -X POST ${data.external.read_credentials.result.tokenurl}/${data.external.read_credentials.result.ENV}/as/token \
         -H 'Authorization: Basic ${local.encodedclient}' \
         -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=client_credentials' | jq -r .access_token > token.json)
echo "$mytoken"
     EOT
   }
}

data "local_file" "token_file" {
  depends_on = [null_resource.get_token]
  filename = "token.json"
}

locals {
  seemytoken = trimspace(data.local_file.token_file.content)
}

output "whyme" {
 value = "${local.seemytoken}"
}

resource "null_resource" "build_json" {

   depends_on = [data.local_file.token_file,null_resource.get_token]
   provisioner "local-exec" {
     command = <<EOT
#sleep $((1 + RANDOM % 300))
NAME=$(shuf -n 1 namesnospaces)
MAILDOMAIN=$(shuf -n 1 MailDomains)
MAIL="$NAME"@"$MAILDOMAIN"
AGENT=$(shuf -n 1 Agents)
LOWRISK=${data.external.read_credentials.result.LOWRISK}
PLATFORM=$(shuf -n 1 Platforms)
APP=$(shuf -n 1 AppsUsed)
RISKID=${data.external.read_credentials.result.RISKPOLICYID}
IP=${local.ip_address}
json_content=$(cat risk.template)
echo "" > outfile.json
echo "I AM HERE"
updated_json=$(echo $json_content | jq --arg a "$MAIL" --arg b "$LOWRISK" --arg c "$AGENT" --arg d "$PLATFORM" --arg e "$APP" --arg f "$RISKID" --arg g "$IP" --arg h "$NAME" \
'.event.user.id = $a | .event.inducerisk = $b | .event.browser.userAgent = $c | .event.browser.platform = $d | .event.origin = $e | .riskPolicySet.id = $f | .event.ip = $g | .event.user.name = $h' > outfile.json )
EOT
}
}

data "local_file" "formatted_json" {
  depends_on = [data.local_file.formatted_json,null_resource.build_json]
  filename = "outfile.json"
}

locals {
  encodedjson = base64encode(data.local_file.formatted_json.content)
}

provider "http" {} 

data "http" "run_api_request" {
 count = 100
    depends_on = [local.seemytoken,local.encodedjson]
    url = "${data.external.read_credentials.result.api_url}/${data.external.read_credentials.result.ENV}/riskEvaluations"
    method = "POST"
    request_headers = {
     Content-Type = "application/json"
     Authorization = "Bearer ${local.seemytoken}"
    }
    request_body = "${data.local_file.formatted_json.content}"
 }

output "response_body" {
  value = { for k, v in data.http.run_api_request : k => v.response_body}
}
