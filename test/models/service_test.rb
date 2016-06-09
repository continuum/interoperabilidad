require 'test_helper'

class ServiceTest < ActiveSupport::TestCase

  test '#last_version returns the version number of the last service version' do
    service = Service.create(
      organization: organizations(:SEGPRES),
      name: 'test-service',
      spec_file: StringIO.new(VALID_SPEC)
    )
    assert_equal 1, service.last_version_number
    # VALID_SPEC is loaded by test_helper
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC))
    assert_equal 2, service.last_version_number
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC))
    assert_equal 3, service.last_version_number
  end
end
