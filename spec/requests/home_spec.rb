require "rails_helper"

RSpec.describe "Home" do
  it "redirects unauthenticated users to sign in" do
    get root_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the dashboard for signed-in users" do
    user = User.create!(email: "user@example.com", password: "password", confirmed_at: Time.current)

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Keep your circles updated without the pressure to reply.")
    expect(response.body).not_to include("Share once, reach everyone")
  end
end
