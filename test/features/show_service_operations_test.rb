require "test_helper"
require_relative 'support/ui_test_helper'

class ShowServiceOperationsTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    @service_v = Service.create!(
      name: "PetsServiceName",
      organization: organizations(:minsal),
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:perico))
  end

  test "Show service operations" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    within ".container-verbs" do
      assert_selector("a", text: "PUT/pets")
      assert_selector("a", text: "POST/pets")
      assert_selector("a", text: "POST/users")
      assert_selector("a", text: "GET/users/login")
      assert_selector("a", text: "GET/pets/{petId}")
      assert_selector("a", text: "POST/pets/{petId}")
      assert_selector("a", text: "DELETE/pets/{petId}")
      assert_selector("a", text: "POST/stores/order")
      assert_selector("a", text: "GET/users/logout")
      assert_selector("a", text: "GET/pets/findByTags")
      assert_selector("a", text: "GET/users/{username}")
      assert_selector("a", text: "PUT/users/{username}")
      assert_selector("a", text: "DELETE/users/{username}")
      assert_selector("a", text: "GET/pets/findByStatus")
      assert_selector("a", text: "POST/users/createWithList")
      assert_selector("a", text: "POST/users/createWithArray")
      assert_selector("a", text: "GET/stores/order/{orderId}")
      assert_selector("a", text: "DELETE/stores/order/{orderId}")
    end
  end

  test "We don't fail on operations with paths ending with a slash" do
    test_service = Service.create!(
      name: "TrickyService",
      organization: organizations(:minsal),
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/with-trailing-slashes.yaml")
    ).create_first_version(users(:perico))
    visit organization_service_service_version_path(
      test_service.organization, test_service.service, test_service
    )
    find(".container-verbs a", text: "GET/calendars/searchByName/").click
    assert_content "Texto coincidente a buscar en el campo pertenece a o nombre"
  end
end
