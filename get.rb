# frozen_string_literal: true

require "yaml"
require "googleauth"
require "google/apis/sheets_v4"
require "googleauth/stores/file_token_store"
require "fileutils"

APPLICATION_NAME = "[YOUR APPLICATION NAME IN GOOGLE CLOUD]"
# Download client secret from google cloud platform
# https://console.cloud.google.com/
CREDENTIALS_PATH = "./client_secret.json"
SHEET_ID = "[YOUR SHEET ID LIKE AsDfGk..]"
SHEET_NAME = "[YOUR SEET NAME LIKE sheet1]"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob"
TOKEN_PATH = "token.yaml"
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = "default"
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
service = Google::Apis::SheetsV4::SheetsService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

range = "#{SHEET_NAME}!A1:B1"

# read spreadsheet
response = service.get_spreadsheet_values(sheet_id, range)
pp response

# write spreadsheet
values = [[2, 2]]
service.update_spreadsheet_value(
  SHEET_ID,
  range,
  { values: values },
  value_input_option: "USER_ENTERED"
)
