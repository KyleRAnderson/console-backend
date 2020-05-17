def sign_in_user(user)
  post user_session_path, params: { user: {
                            email: user.email,
                            password: DEFAULT_PASSWORD,
                          } }
  token = response.headers['Authorization']
  @headers = { 'Authorization': token }
end
