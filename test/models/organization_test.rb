require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase

  test "#can_create_service_or_version? returns true for a user who belongs to the organization" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert organizations(:sii).is_member?(perico)
  end

  test "#can_create_service_or_version? returns true for a user who belongs to the organization and is Service Provider" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Service Provider")
    assert organizations(:sii).can_create_service_or_version?(perico)
  end

  test "#can_create_service_or_version? returns false for a user who belongs to the organization and is not a Service Provider" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not organizations(:sii).can_create_service_or_version?(perico)
  end

  test "#can_create_service_or_version? returns false for a user who does not belongs to the organization and is Service Provider" do
    pepito = users(:pepito)
    pepito.roles.create!(organization: organizations(:sii), name: "Service Provider")
    assert_not organizations(:segpres).can_create_service_or_version?(pepito)
  end

  test "#can_create_service_or_version? returns false for a user who does not belongs to the organization and is not a Service Provider" do
    pepito = users(:pepito)
    pepito.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not organizations(:segpres).can_create_service_or_version?(pepito)
  end

  test "#can_create_agreements_with_this_organization? returns true for a user who does not belongs to the organization and role is Create Agreement" do
    user = users(:perico)
    user_org = organizations(:segpres)
    org = organizations(:minsal)
    user.roles.create(organization: user_org, name: "Create Agreement")
    assert org.can_create_agreements_with_this_organization?(user)
  end

  test "#can_create_agreements_with_this_organization? returns false for a user who does not belongs to the organization and role is Service Provider" do
    user = users(:perico)
    user_org = organizations(:segpres)
    org = organizations(:minsal)
    user.roles.create(organization: user_org, name: "Service Provider")
    assert_not org.can_create_agreements_with_this_organization?(user)
  end

  test "#can_create_agreements_with_this_organization? return false for a user who belongs to the organization and role is Create Agreement" do
    user = users(:perico)
    user_org = organizations(:segpres)
    user.roles.create(organization: user_org, name: "Create Agreement")
    assert_not user_org.can_create_agreements_with_this_organization?(user)
  end

  test "#can_create_agreements_with_this_organization? return false for a user who belongs to the organization and role is Service Provider" do
    user = users(:perico)
    user_org = organizations(:segpres)
    user.roles.create(organization: user_org, name: "Service Provider")
    assert_not user_org.can_create_agreements_with_this_organization?(user)
  end

end
