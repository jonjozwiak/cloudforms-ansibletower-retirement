#
# Description: This method launches an Ansible Tower job template
#

module ManageIQ
  module Automate
    module AutomationManagement
      module AnsibleTower
        module Service
          module Provisioning
            module StateMachines
              module Provision
                class Provision
                  JOB_CLASS = 'ManageIQ_Providers_AnsibleTower_AutomationManager_Job'.freeze
                  
                  def initialize(handle = $evm)
                    @handle = handle
                  end

                  def main
                    @handle.log("info", "Starting Ansible Tower Retirement Provisioning")
                    run($evm.root['service'], identify_retirement_template($evm.root['service']))
                  end

                  private
                  
				  # I added / tweaked the below function from preprovision
                  # Set the job template to the 'retire' template
                  def identify_retirement_template(service)
                    @handle.log("info", "manager = #{service.configuration_manager.name}.  ID <#{service.configuration_manager.id}>")
                    @handle.log("info", "provisioned template = #{service.job_template.name}")

                    # Find template with prefix
                    retire_prefix = "retire_"
                    
                    # retire_job_template = $evm.vmdb('ConfigurationScript').find_by_name("#{retire_prefix}#{service.job_template.name}")
                    retire_job_template = $evm.vmdb('ConfigurationScript').where(manager_id: "#{service.configuration_manager.id}", name: "#{retire_prefix}#{service.job_template.name}").first rescue nil
                    raise "Retirement Ansible Job Template not found" if retire_job_template.nil?

      				$evm.log(:info, "retirement template = <#{retire_job_template.name}>.  ID <#{retire_job_template.id}>")
                    
                    return retire_job_template
                    
                    # Caution: job options may contain passwords.
                    # @handle.log("info", "job options = #{service.job_options.inspect}")
                  end

                  def launch_ansible_job(job_template, args)
                    @handle.log(:info, "Processing Job Template #{job_template.name}")
                    
                    @handle.log(:info, "Job Arguments #{args}")

                    job = @handle.vmdb(JOB_CLASS).create_job(job_template, args)

                    @handle.log(:info, "Launched Ansible Tower Job (#{job.name}) Scheduled Job ID: #{job.id} Ansible Job ID: #{job.ems_ref}")
                    @handle.set_state_var(:ansible_job_id, job.id)
                  end
                  
                  def run(service, retirement_job_template)
                    #$evm.log(:info, "DUMP SERVICE OBJECT = <#{service}>.")
                    #service.attributes.each { |k, v| @handle.log(:info, "Root:<service> Attribute - #{k}: #{v}")}
                    job_options = service.options[:create_options] 
                    launch_ansible_job(retirement_job_template, job_options)
                  rescue => err
                    @handle.root['ae_result'] = 'error'
                    @handle.root['ae_reason'] = err.message
                    @handle.log("error", "Template #{service.job_template.name} launching failed. Reason: #{err.message}")
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::AutomationManagement::AnsibleTower::Service::Provisioning::StateMachines::Provision::Provision.new.main
end
