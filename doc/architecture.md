# ADRL architecture

It’s possible to run all the components of ADRL on a single server;
that’s what we did at the beginning and it still works for local
development.  The `all-in-one_vagrant.yml` playbook in our [Ansible
repository](https://github.library.ucsb.edu/ADRL/sufia-centos) will
provision a Vagrant VM will Fedora, Solr, PSQL, and all the Rails
components for a functioning instance of ADRL.

But for production, it’s better to split these components up.  Running
Fedora, Solr, PostgreSQL, and the Rails application itself all on
separate servers improves performance and reliability and makes
upgrading each service easier.

## Provisioning with Ansible Tower

Currently we provision production ADRL servers with
[Ansible Tower](https://ansibletower.library.ucsb.edu/#/login).  The
setup is roughly:

1. In Settings, add SCM credentials for GitHub Enterprise, so that
   Tower can clone our
   [Ansible repository](https://github.library.ucsb.edu/ADRL/sufia-centos).

2. Add ADRL as a new project.  It’s recommended to check “Update on
   Launch” so that the provisioning scripts are up-to-date before each
   run.

3. Add new inventories for each server to be provisioned.

4. Add machine credentials for SSH access to each server.  Add the
   sudo password(s) if the playbook you’re running on that server will
   require privilege escalation.

5. Create job templates for each playbook.  Tower runs playbooks
   non-interactively, so you can’t specify `vars_prompt`; instead, add
   the variables to the “Extra Variables” field in the job template
   and check “prompt on launch”.  (In our case, the Tomcat playbook
   needs to know the hostname of the PostgreSQL server and the ADRL
   application playbook needs to know the hostnames of all the other
   servers, as well as its own public IP/FQDN.)

6. Run the job templates! 🚀

## Managing the infrastructure

Currently we keep everything on a private network and only expose the
ADRL Rails application via a proxy server.  If you’re not doing this,
you’ll have to tighten up the security on some of the services:

- Prevent PSQL from accepting connections from any servers other than
  the Tomcat server and the Rails server: see
  https://github.library.ucsb.edu/ADRL/sufia-centos/blob/master/roles/postgresql/templates/pg_hba.conf.j2#L17
  and
  https://github.library.ucsb.edu/ADRL/sufia-centos/blob/master/roles/postgresql/handlers/main.yml#L32

- Fine-tune the Marmotta configuration instead of allowing all remote
  operations:
  https://github.library.ucsb.edu/ADRL/sufia-centos/blob/master/roles/tomcat/templates/system-config.properties.j2

## Upgrading the infrastructure

Some gotchas:

- Fedora keeps its metadata in PostgreSQL rather than in the internal
  LevelDB.  If you connect a new instance of the ADRL Rails
  application to an existing Fedora server, it will still have cached
  data in PostgreSQL, which can cause odd 500 errors if you try to
  clean out Fedora via `ActiveFedora::Cleaner.clean!`  In this case
  you’ll need to manually wipe out Fedora’s tables in PSQL.
