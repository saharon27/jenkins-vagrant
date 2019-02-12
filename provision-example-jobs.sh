#!/bin/bash
set -eux
domain=$(hostname --fqdn)
source /vagrant/jenkins-cli.sh


# create example jobs.
# see https://jenkins.io/doc/pipeline/steps/
# see http://javadoc.jenkins-ci.org/jenkins/model/Jenkins.html
# see http://javadoc.jenkins.io/plugin/workflow-job/org/jenkinsci/plugins/workflow/job/WorkflowJob.html
# see http://javadoc.jenkins.io/plugin/workflow-cps/org/jenkinsci/plugins/workflow/cps/CpsFlowDefinition.html
# see http://javadoc.jenkins-ci.org/hudson/model/FreeStyleProject.html
# see http://javadoc.jenkins-ci.org/hudson/model/Label.html
# see http://javadoc.jenkins-ci.org/hudson/tasks/Shell.html
# see http://javadoc.jenkins-ci.org/hudson/tasks/ArtifactArchiver.html
# see http://javadoc.jenkins-ci.org/hudson/tasks/BatchFile.html
# see http://javadoc.jenkins.io/plugin/mailer/hudson/tasks/Mailer.html
# see https://github.com/jenkinsci/powershell-plugin/blob/master/src/main/java/hudson/plugins/powershell/PowerShell.java
# see https://github.com/jenkinsci/git-plugin/blob/master/src/main/java/hudson/plugins/git/GitSCM.java
# see https://github.com/jenkinsci/git-plugin/blob/master/src/main/java/hudson/plugins/git/extensions/impl/CleanBeforeCheckout.java
# see https://github.com/jenkinsci/xunit-plugin/blob/master/src/main/java/org/jenkinsci/plugins/xunit/XUnitBuilder.java

# create the dump-environment folder to contain all of our dump jobs.
jgroovy = <<'EOF'
import jenkins.model.Jenkins
import com.cloudbees.hudson.plugins.folder.Folder

folder = new Folder(Jenkins.instance, 'environment-Info')
folder.save()

Jenkins.instance.add(folder, folder.name)
EOF

jgroovy = <<'EOF'
import jenkins.model.Jenkins
import hudson.model.FreeStyleProject
import hudson.model.labels.LabelAtom
import hudson.tasks.Shell

folder = Jenkins.instance.getItem('environment-Info')

project = new FreeStyleProject(folder, 'linux')
project.assignedLabel = new LabelAtom('linux')
project.buildersList.add(new Shell(
'''\
cat /etc/lsb-release
uname -a
env
locale
id
'''))

folder.add(project, project.name)
EOF

jgroovy = <<'EOF'
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

folder = Jenkins.instance.getItem('dump-environment')

project = new WorkflowJob(folder, 'linux-pipeline')
project.definition = new CpsFlowDefinition("""\
pipeline {
    agent {
        label 'linux'
    }
    stages {
        stage('Build') {
            steps {
                sh '''
cat /etc/lsb-release
uname -a
env
locale
id
'''
            }
        }
    }
}
""",
true)

folder.add(project, project.name)
EOF

jgroovy = <<'EOF'
import jenkins.model.Jenkins
import hudson.model.FreeStyleProject
import hudson.tasks.Shell

project = new FreeStyleProject(jenkins.instancelder, 'linux')
project.buildersList.add(new Shell(
'''\
echo "Hello world My name is CHUCK NORRIS"
'''))
Jenkins.instance.add(project, project.name)
EOF
