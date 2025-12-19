require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "shows confirmation page for matching signed-in user" do
    invitation = invitations(:pending)
    sign_in users(:one)

    get invitation_url(token: invitation.token)

    assert_response :success
    assert_select "h1", "Accept your invitation"
    assert_select "form[action='#{accept_invitation_path(invitation.token)}'][method='post']" do
      assert_select "input[type=submit][value='Accept invitation']"
    end
  end

  test "accepts invitation with matching email" do
    invitation = invitations(:pending)
    sign_in users(:one)

    post accept_invitation_path(invitation.token)

    assert_redirected_to group_path(invitation.group)
    assert_equal "You have been added to #{invitation.group.name}.", flash[:notice]

    invitation.reload
    assert_not_nil invitation.accepted_at
    assert_equal users(:one), invitation.invited_user
  end

  test "signs out and redirects when emails do not match" do
    invitation = invitations(:pending)
    sign_in users(:two)

    post accept_invitation_path(invitation.token)

    assert_redirected_to new_user_registration_path(invite_token: invitation.token)
    assert_equal "Please sign up or sign in with #{invitation.email} to accept this invitation.", flash[:alert]
    assert_nil session["warden.user.user.key"]
  end

  test "alerts when invitation already used" do
    invitation = invitations(:used)
    sign_in users(:one)

    post accept_invitation_path(invitation.token)

    assert_redirected_to group_path(invitation.group)
    assert_equal "This invitation has already been used.", flash[:alert]
  end
end
