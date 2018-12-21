require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::PostProcess do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_template_provision_request, :requester => admin) }
  let(:ansible_tower_manager) { FactoryBot.create(:automation_manager) }
  let(:job_template) { FactoryBot.create(:ansible_configuration_script, :manager => ansible_tower_manager) }
  let(:service_ansible_tower) { FactoryBot.create(:service_ansible_tower, :job_template => job_template) }
  let(:task) { FactoryBot.create(:service_template_provision_task, :destination => service_ansible_tower, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceTemplateProvisionTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision') }
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:errormsg) { "simple error" }

  shared_examples_for "postprocess_error" do
    it "postprocess" do
      allow(svc_service).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:postprocess).and_return(nil)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq(rc)
      expect(ae_service.root['ae_reason']).to eq(msg)
      expect(svc_task.miq_request[:options][:user_message]).to eq(msg)
    end
  end

  context "service not found" do
    let(:msg) { 'Service not found' }
    let(:rc) { 'error' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service_template_provision_task' => task,
                                         'service_action'                  => 'Provision')
    end
    it_behaves_like "postprocess_error"
  end

  context "invalid service_action" do
    let(:msg) { 'Invalid service_action' }
    let(:rc) { 'error' }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'                         => svc_service,
                                         'service_template_provision_task' => task,
                                         'service_action'                  => 'fred')
    end
    it_behaves_like "postprocess_error"
  end

  context "postprocess" do
    it "successful scenario" do
      allow(svc_task).to receive(:destination).and_return(svc_service)
      allow(svc_service).to receive(:postprocess).and_return(nil)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq("ok")
    end
  end
end
