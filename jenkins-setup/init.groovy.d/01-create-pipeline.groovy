import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec
import hudson.plugins.git.UserRemoteConfig

Jenkins jenkins = Jenkins.get()

String jobName = "OwlAudit-Pipeline"

if (jenkins.getItem(jobName) == null) {
    println "--> [Auto-Config] Creando Job predeterminado: ${jobName}..."
    try {
        WorkflowJob job = jenkins.createProject(WorkflowJob.class, jobName)

        String repoUrl = "https://github.com/AndresVeas/deploy-auditowl.git"
        String branch = "*/main"
        String scriptPath = "Jenkinsfile"

        List<UserRemoteConfig> remotes = [new UserRemoteConfig(repoUrl, null, null, null)]
        List<BranchSpec> branches = [new BranchSpec(branch)]

        GitSCM scm = new GitSCM(
            remotes,
            branches,
            false,
            Collections.emptyList(),
            null,
            null,
            Collections.emptyList()
        )

        CpsScmFlowDefinition flowDefinition = new CpsScmFlowDefinition(scm, scriptPath)
        flowDefinition.setLightweight(true)

        job.setDefinition(flowDefinition)
        job.save()
        println "--> [Auto-Config] Job ${jobName} creado y configurado exitosamente!"
    } catch (Exception e) {
        println "--> [Auto-Config ERROR] No se pudo crear el Job: " + e.getMessage()
    }
} else {
    println "--> [Auto-Config] El Job ${jobName} ya existe en Jenkins."
}
