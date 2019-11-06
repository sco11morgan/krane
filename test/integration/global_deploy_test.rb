# frozen_string_literal: true
require 'integration_test_helper'

class GlobalDeployTest < Krane::IntegrationTest
  def test_global_deploy_task_success
    assert_deploy_success(deploy_global_fixtures('globals'))

    assert_logs_match_all([
      "Phase 1: Initializing deploy",
      "Using resource selector test=",
      "All required parameters and files are present",
      "Discovering resources:",
      "  - StorageClass/testing-storage-class",
      "Phase 2: Checking initial resource statuses",
      %r{StorageClass\/testing-storage-class[\w-]+\s+Not Found},
      "Phase 3: Deploying all resources",
      %r{Deploying StorageClass\/testing-storage-class[\w-]+ \(timeout: 300s\)},
      "Don't know how to monitor resources of type StorageClass.",
      %r{Assuming StorageClass\/testing-storage-class[\w-]+ deployed successfully.},
      %r{Successfully deployed in 0.[\d]+s: StorageClass\/testing-storage-class},
      "Result: SUCCESS",
      "Successfully deployed 1 resource",
      "Successful resources",
      "StorageClass/testing-storage-class",
    ])
  end

  def test_global_deploy_task_success_timeout
    assert_deploy_failure(deploy_global_fixtures('globals', global_timeout: 0), :timed_out)

    assert_logs_match_all([
      "Phase 1: Initializing deploy",
      "Using resource selector test=",
      "All required parameters and files are present",
      "Discovering resources:",
      "  - StorageClass/testing-storage-class",
      "Phase 2: Checking initial resource statuses",
      %r{StorageClass\/testing-storage-class[\w-]+\s+Not Found},
      "Phase 3: Deploying all resources",
      %r{Deploying StorageClass\/testing-storage-class[\w-]+ \(timeout: 300s\)},
      "Result: TIMED OUT",
      "Timed out waiting for 1 resource to deploy",
      %r{StorageClass\/testing-storage-class[\w-]+: GLOBAL WATCH TIMEOUT \(0 seconds\)},
      "If you expected it to take longer than 0 seconds for your deploy to roll out, increase --max-watch-seconds.",
    ])
  end

  def test_global_deploy_task_success_verify_false
    assert_deploy_success(deploy_global_fixtures('globals', verify_result: false))

    assert_logs_match_all([
      "Phase 1: Initializing deploy",
      "Using resource selector test=",
      "All required parameters and files are present",
      "Discovering resources:",
      "  - StorageClass/testing-storage-class",
      "Phase 2: Checking initial resource statuses",
      %r{StorageClass\/testing-storage-class[\w-]+\s+Not Found},
      "Phase 3: Deploying all resources",
      %r{Deploying StorageClass\/testing-storage-class[\w-]+ \(timeout: 300s\)},
      "Result: SUCCESS",
      "Deployed 1 resource",
      "Deploy result verification is disabled for this deploy.",
      "This means the desired changes were communicated to Kubernetes, but the"\
      " deploy did not make sure they actually succeeded.",
    ])
  end

  def test_global_deploy_task_empty_selector_validation_failure
    assert_deploy_failure(deploy_global_fixtures('globals', selector: ""))
    assert_logs_match_all([
      "Phase 1: Initializing deploy",
      "Result: FAILURE",
      "Configuration invalid",
      "- Selector is required",
    ])
  end

  def test_global_deploy_task_success_selector
    selector = "app=krane"
    assert_deploy_success(deploy_global_fixtures('globals', selector: selector))

    assert_logs_match_all([
      "Phase 1: Initializing deploy",
      "Using resource selector #{selector}",
      "All required parameters and files are present",
      "Discovering resources:",
      "  - StorageClass/testing-storage-class",
      "Phase 2: Checking initial resource statuses",
      %r{StorageClass\/testing-storage-class[\w-]+\s+Not Found},
      "Phase 3: Deploying all resources",
      %r{Deploying StorageClass\/testing-storage-class[\w-]+ \(timeout: 300s\)},
      "Don't know how to monitor resources of type StorageClass.",
      %r{Assuming StorageClass\/testing-storage-class[\w-]+ deployed successfully.},
      %r{Successfully deployed in 0.[\d]+s: StorageClass\/testing-storage-class},
      "Result: SUCCESS",
      "Successfully deployed 1 resource",
      "Successful resources",
      "StorageClass/testing-storage-class",
    ])
  end

  def test_global_deploy_task_failure
    result = deploy_global_fixtures('globals') do |fixtures|
      fixtures.dig("storage_classes.yml", "StorageClass").first["metadata"]['badField'] = "true"
    end
    assert_deploy_failure(result)

    assert_logs_match_all([
      "Phase 1: Initializing deploy",
      "Using resource selector test=",
      "All required parameters and files are present",
      "Discovering resources:",
      "  - StorageClass/testing-storage-class",
      "Result: FAILURE",
      "Template validation failed",
    ])
  end
end
