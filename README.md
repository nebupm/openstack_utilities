# openstack_utilities
A bunch of Bash and python scripts to help with day to day openstack tasks

<a  name="scripts"></a>
## Scripts

1. [ migration_status.sh ](#migration_status.sh)
2. [ live_migrate_instances.sh ](#live_migrate_instances.sh)
3. [ cold_migrate_instances.sh ](#cold_migrate_instances.sh)
4. [ getdeploystatus.sh ](#getdeploystatus.sh)


<a  name="migration_status.sh"></a>

## migration_status.sh

This script is useful to monitor the progress of the migration of your instance in openstack. You need to run this script with instance ID as the argument.

> Migration : Moving an instance from one hypervisor to another hypervisor.

> Cold migration : Migrating an instance that is either shutdown and can be shutdown during migration.

> Live Migration : Migrating an instance that is running and it cant be shutdown.

#### Command
```
./migration_status.sh 1a2345b6-7c89-0123-4d56-7e8f9a0123bc
```

#### Output of Command (Monitoring a cold migration)
```
[2020-12-11 17:37:05][migration_status.sh]: ##############################################################
[2020-12-18 13:37:07][migration_status.sh]:[Before Migration]: ID=1a2345b6-7c89-0123-4d56-7e8f9a0123bc, Name=my_test_instance, HOST=compute001_az01.example-cloud.co.uk
+--------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field                                | Value                                                                                                                                                  |
+--------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                                                                                                                 |
| OS-EXT-AZ:availability_zone          | 00021-1                                                                                                                                                |
| OS-EXT-SRV-ATTR:host                 | compute001_az01.example-cloud.co.uk                                                                                                                    |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute001_az01.example-cloud.co.uk                                                                                                                    |
| OS-EXT-SRV-ATTR:instance_name        | instance-0001234a                                                                                                                                      |
| OS-EXT-STS:power_state               | Shutdown                                                                                                                                               |
| OS-EXT-STS:task_state                | resize_migrating                                                                                                                                       |
| OS-EXT-STS:vm_state                  | stopped                                                                                                                                                |
| OS-SRV-USG:launched_at               | 2020-07-07T23:12:06.000000                                                                                                                             |
| OS-SRV-USG:terminated_at             | None                                                                                                                                                   |
| accessIPv4                           |                                                                                                                                                        |
| accessIPv6                           |                                                                                                                                                        |
| addresses                            | my_net001=10.1.0.113, 101.101.101.2                                                                                                                    |
| config_drive                         |                                                                                                                                                        |
| created                              | 2020-07-07T23:11:59Z                                                                                                                                   |
| flavor                               | m1.small (00a0ab0f-e0f0-1234-b000-123c12345b67)                                                                                                        |
| hostId                               | fd1fefb11cc1fad11ea11111a1d1e11111111a111cdc11d11e1e1afa                                                                                               |
| id                                   | 1a2345b6-7c89-0123-4d56-7e8f9a0123bc                                                                                                                   |
| image                                | Ubuntu 18.04 - 280720 (fa1111f1-1111-1c11-aa11-1111111c1fdc)                                                                                           |
| key_name                             | my_key-pair-001                                                                                                                                        |
| name                                 | my_test_instance                                                                                                                                       |
| os-extended-volumes:volumes_attached | [{u'id': u'12c3d45b-6789-0123-b4a5-6789df01d2ca'}, {u'id': u'82face20-30a0-49c5-8cfd-42cdd11f9f7f'}, {u'id': u'5e0a2111-6314-4c2a-8b25-054e3946bebc'}] |
| progress                             | 0                                                                                                                                                      |
| project_id                           | 0000d000b0000a0e0e000c000000c000                                                                                                                       |
| properties                           | role='my_role', ssh_user='ubuntu'                                                                                                                      |
| security_groups                      | [{u'name': u'my_test_instance'}]                                                                                                                       |
| status                               | RESIZE                                                                                                                                                 |
| updated                              | 2020-12-18T13:37:06Z                                                                                                                                   |
| user_id                              | 111f1111c11b11ef1c1a11cc1d11d111                                                                                                                       |
+--------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+
[2020-12-18 13:37:10][migration_status.sh]:[my_test_instance][1a2345b6-7c89-0123-4d56-7e8f9a0123bc]: Getting migration ID.
[2020-12-18 13:37:12][migration_status.sh]:[my_test_instance][1a2345b6-7c89-0123-4d56-7e8f9a0123bc]: Checking the status of migration
[2020-12-18 13:37:14][migration_status.sh]:[my_test_instance][1a2345b6-7c89-0123-4d56-7e8f9a0123bc][resize]: Cold migration
[2020-12-18 13:37:14][migration_status.sh]:[my_test_instance][1a2345b6-7c89-0123-4d56-7e8f9a0123bc][resize]: Getting cold migration details.
DATETIME,MIGRATION_ID,INSTANCE_ID,SOURCE_NODE -> DESTINATION_NODE,MEMORY_REMAINING_BYTES,DISK_REMAINING_BYTES,STATUS,UPDATED
2020-12-18T13:37:16.997194010,13019,1a2345b6-7c89-0123-4d56-7e8f9a0123bc,compute001_az01.example-cloud.co.uk -> compute021_az02.example-cloud.co.uk,Mem:NAN,Disk:NAN,migrating,2020-12-18T13:37:06
2020-12-18T13:37:23.228963950,13019,1a2345b6-7c89-0123-4d56-7e8f9a0123bc,compute001_az01.example-cloud.co.uk -> compute021_az02.example-cloud.co.uk,Mem:NAN,Disk:NAN,migrating,2020-12-18T13:37:06
...
2020-12-18T13:39:19.681987053,13019,1a2345b6-7c89-0123-4d56-7e8f9a0123bc,compute001_az01.example-cloud.co.uk -> compute021_az02.example-cloud.co.uk,Mem:NAN,Disk:NAN,migrating,2020-12-18T13:37:06
2020-12-18T13:39:25.810871616,13019,1a2345b6-7c89-0123-4d56-7e8f9a0123bc,compute001_az01.example-cloud.co.uk -> compute021_az02.example-cloud.co.uk,Mem:NAN,Disk:NAN,post-migrating,2020-12-18T13:39:19
2020-12-18T13:39:31.899990544,13019,1a2345b6-7c89-0123-4d56-7e8f9a0123bc,compute001_az01.example-cloud.co.uk -> compute021_az02.example-cloud.co.uk,Mem:NAN,Disk:NAN,post-migrating,2020-12-18T13:39:19
2020-12-18T13:39:38.034044155,13019,1a2345b6-7c89-0123-4d56-7e8f9a0123bc,compute001_az01.example-cloud.co.uk -> compute021_az02.example-cloud.co.uk,Mem:NAN,Disk:NAN,finished,2020-12-18T13:39:34
[2020-12-18 13:39:38][migration_status.sh]:[my_test_instance][1a2345b6-7c89-0123-4d56-7e8f9a0123bc]: After Migration.

+--------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field                                | Value                                                                                                                                                  |
+--------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                                                                                                                 |
| OS-EXT-AZ:availability_zone          | 00021-1                                                                                                                                                |
| OS-EXT-SRV-ATTR:host                 | compute021_az02.example-cloud.co.uk                                                                                                                    |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute021_az02.example-cloud.co.uk                                                                                                                    |
| OS-EXT-SRV-ATTR:instance_name        | instance-0001234a                                                                                                                                      |
| OS-EXT-STS:power_state               | Shutdown                                                                                                                                               |
| OS-EXT-STS:task_state                | None                                                                                                                                                   |
| OS-EXT-STS:vm_state                  | resized                                                                                                                                                |
| OS-SRV-USG:launched_at               | 2020-12-18T13:39:34.000000                                                                                                                             |
| OS-SRV-USG:terminated_at             | None                                                                                                                                                   |
| accessIPv4                           |                                                                                                                                                        |
| accessIPv6                           |                                                                                                                                                        |
| addresses                            | my_net001=10.1.0.113, 101.101.101.2                                                                                                                    |
| config_drive                         |                                                                                                                                                        |
| created                              | 2020-07-07T23:11:59Z                                                                                                                                   |
| flavor                               | m1.small (00a0ab0f-e0f0-1234-b000-123c12345b67)                                                                                                        |
| hostId                               | ab1cdef11ab1cde11fa11111b1c1d11111111e111fab11c11d1e1fab                                                                                               |
| id                                   | 1a2345b6-7c89-0123-4d56-7e8f9a0123bc                                                                                                                   |
| image                                | Ubuntu 18.04 - 280720 (fa1111f1-1111-1c11-aa11-1111111c1fdc)                                                                                           |
| key_name                             | my_key-pair-001                                                                                                                                        |
| name                                 | my_test_instance                                                                                                                                       |
| os-extended-volumes:volumes_attached | [{u'id': u'12c3d45b-6789-0123-b4a5-6789df01d2ca'}]                                                                                                     |
| progress                             | 0                                                                                                                                                      |
| project_id                           | 0000d000b0000a0e0e000c000000c000                                                                                                                       |
| properties                           | role='my_role', ssh_user='ubuntu'                                                                                                                      |
| security_groups                      | [{u'name': u'my_test_instance'}]                                                                                                                       |
| status                               | VERIFY_RESIZE                                                                                                                                          |
| updated                              | 2020-12-18T13:39:34Z                                                                                                                                   |
| user_id                              | 111f1111c11b11ef1c1a11cc1d11d111                                                                                                                       |
+--------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+
[2020-12-18 13:39:40][migration_status.sh]:##############################################################
```

#### Output of Command (Monitoring a Live migration)
```
[2020-12-18 13:53:06][migration_status.sh]:[Before Migration]: ID=a2b22222-2c22-22de-f2a2-2222222b2cde, Name=haproxy-inst001, HOST=compute031_az04.example-cloud.co.uk
+--------------------------------------+-------------------------------------------------------------------------------+
| Field                                | Value                                                                         |
+--------------------------------------+-------------------------------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                                        |
| OS-EXT-AZ:availability_zone          | 00021-1                                                                       |
| OS-EXT-SRV-ATTR:host                 | compute031_az04.example-cloud.co.uk                                           |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute031_az04.example-cloud.co.uk                                           |
| OS-EXT-SRV-ATTR:instance_name        | instance-98712345                                                             |
| OS-EXT-STS:power_state               | Running                                                                       |
| OS-EXT-STS:task_state                | migrating                                                                     |
| OS-EXT-STS:vm_state                  | active                                                                        |
| OS-SRV-USG:launched_at               | 2020-12-10T18:02:13.000000                                                    |
| OS-SRV-USG:terminated_at             | None                                                                          |
| accessIPv4                           |                                                                               |
| accessIPv6                           |                                                                               |
| addresses                            | my_net_002=10.11.12.13                                                        |
| config_drive                         |                                                                               |
| created                              | 2020-12-10T18:02:04Z                                                          |
| flavor                               | m1.small (00a0ab0f-e0f0-1234-b000-123c12345b67)                               |
| hostId                               | e8b19f57f1f107b4f91fc248aefbd4a6b79c8b45cec730e6dff421a5                      |
| id                                   | a2b22222-2c22-22de-f2a2-2222222b2cde                                          |
| image                                | Ubuntu 18.04 - 280720 (fa1111f1-1111-1c11-aa11-1111111c1fdc)                  |
| key_name                             | my_key-pair-002                                                               |
| name                                 | haproxy-inst001                                                               |
| os-extended-volumes:volumes_attached | []                                                                            |
| progress                             | 0                                                                             |
| project_id                           | 0000d000b0000a0e0e000c000000c000                                              |
| properties                           |                                                                               |
| security_groups                      | [{u'name': u'sec_grp_001'}]                                                   |
| status                               | MIGRATING                                                                     |
| updated                              | 2020-12-18T13:53:03Z                                                          |
| user_id                              | 111f1111c11b11ef1c1a11cc1d11d111                                              |
+--------------------------------------+-------------------------------------------------------------------------------+
[2020-12-18 13:53:08][migration_status.sh]:[haproxy-inst001][a2b22222-2c22-22de-f2a2-2222222b2cde]: Getting migration ID.
[2020-12-18 13:53:09][migration_status.sh]:[haproxy-inst001][a2b22222-2c22-22de-f2a2-2222222b2cde][]: Getting live migration details.
DATETIME,MIGRATION_ID,INSTANCE_ID,SOURCE_NODE -> DESTINATION_NODE,MEMORY_REMAINING_BYTES,DISK_REMAINING_BYTES,STATUS,UPDATED
2020-12-18T13:53:11.678399452,13034,a2b22222-2c22-22de-f2a2-2222222b2cde,compute031_az04.example-cloud.co.uk -> compute012_az03.example-cloud.co.uk,Mem:0,Disk:0,running,2020-12-18T13:53:09
2020-12-18T13:53:15.281839071,13034,a2b22222-2c22-22de-f2a2-2222222b2cde,compute031_az04.example-cloud.co.uk -> compute012_az03.example-cloud.co.uk,Mem:0,Disk:2119761920,running,2020-12-18T13:53:14
2020-12-18T13:53:18.816094678,13034,a2b22222-2c22-22de-f2a2-2222222b2cde,compute031_az04.example-cloud.co.uk -> compute012_az03.example-cloud.co.uk,Mem:0,Disk:2119761920,running,2020-12-18T13:53:14
2020-12-18T13:53:22.384675305,13034,a2b22222-2c22-22de-f2a2-2222222b2cde,compute031_az04.example-cloud.co.uk -> compute012_az03.example-cloud.co.uk,Mem:0,Disk:920977408,running,2020-12-18T13:53:20
2020-12-18T13:53:25.851699562,13034,a2b22222-2c22-22de-f2a2-2222222b2cde,compute031_az04.example-cloud.co.uk -> compute012_az03.example-cloud.co.uk,Mem:517689344,Disk:0,running,2020-12-18T13:53:25
...
2020-12-18T13:53:57.892966284,13034,a2b22222-2c22-22de-f2a2-2222222b2cde,compute031_az04.example-cloud.co.uk -> compute012_az03.example-cloud.co.uk,Mem:517689344,Disk:0,completed,2020-12-18T13:53:55.000000
2020-12-18T13:53:57.892966284,13034,a2b22222-2c22-22de-f2a2-2222222b2cde,compute031_az04.example-cloud.co.uk -> compute012_az03.example-cloud.co.uk,Mem:517689344,Disk:0,active,2020-12-18T13:53:55
[2020-12-18 13:54:03][migration_status.sh]:[haproxy-inst001][a2b22222-2c22-22de-f2a2-2222222b2cde]: After Migration.
+--------------------------------------+-------------------------------------------------------------------------------+
| Field                                | Value                                                                         |
+--------------------------------------+-------------------------------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                                                        |
| OS-EXT-AZ:availability_zone          | 00021-1                                                                       |
| OS-EXT-SRV-ATTR:host                 | compute012_az03.example-cloud.co.uk                                           |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute012_az03.example-cloud.co.uk                                           |
| OS-EXT-SRV-ATTR:instance_name        | instance-98712345                                                             |
| OS-EXT-STS:power_state               | Running                                                                       |
| OS-EXT-STS:task_state                | None                                                                          |
| OS-EXT-STS:vm_state                  | active                                                                        |
| OS-SRV-USG:launched_at               | 2020-12-10T18:02:13.000000                                                    |
| OS-SRV-USG:terminated_at             | None                                                                          |
| accessIPv4                           |                                                                               |
| accessIPv6                           |                                                                               |
| addresses                            | my_net_002=10.11.12.13                                                        |
| config_drive                         |                                                                               |
| created                              | 2020-12-10T18:02:04Z                                                          |
| flavor                               | m1.small (00a0ab0f-e0f0-1234-b000-123c12345b67)                               |
| hostId                               | b36354f7821e99354ea8f8b07f3a3105982ad802e4d4f5670fb3241d                      |
| id                                   | a2b22222-2c22-22de-f2a2-2222222b2cde                                          |
| image                                | Ubuntu 18.04 - 280720 (fa1111f1-1111-1c11-aa11-1111111c1fdc)                  |
| key_name                             | my_key-pair-002                                                               |
| name                                 | haproxy-inst001                                                               |
| os-extended-volumes:volumes_attached | []                                                                            |
| progress                             | 0                                                                             |
| project_id                           | 0000d000b0000a0e0e000c000000c000                                              |
| properties                           |                                                                               |
| security_groups                      | [{u'name': u'sec_grp_001'}]                                                   |
| status                               | ACTIVE                                                                        |
| updated                              | 2020-12-18T13:53:30Z                                                          |
| user_id                              | 111f1111c11b11ef1c1a11cc1d11d111                                              |
+--------------------------------------+-------------------------------------------------------------------------------+
[2020-12-18 13:54:05][migration_status.sh]:##############################################################

```

[ Top Of Page ](#scripts)

<a  name="live_migrate_instances.sh"></a>

## live_migrate_instances.sh

This script will live migrate all ACTIVE instances from this host. This will achieve a result similar to nova evacuate command, however, this is more controlled and the user has the freedon to stop the migration but breaking the script execution and do required actions before resuming again. This script also depends on migration_status.sh script, it is used to monitor the progress of migration. It will be polling nova migration list and getting an upto date status every 5 seconds.

- Argument 1 (Mandatory) : FQDN of the compute host.
- Argument 2 (Optional) : Number of seconds to wait between migrations. Default : 60 seconds.
= Argument 3 (Optional) : List of instances to exclude from the migration. Example "Prod|Customer1". Default : No exclusion.

#### Command
```
./live_migrate_instances.sh compute031_az04.example-cloud.co.uk 15 "Production|Customer1"

```

[ Top Of Page ](#scripts)

<a  name="cold_migrate_instances.sh"></a>

## cold_migrate_instances.sh

This script will cold migrate all SHUTOFF instances from this host.

- Argument 1 (Mandatory) : FQDN of the compute host. You can extract this name from the following openstack command: openstack scompute service list --service nova-compute
- Argument 2 (Optional) : Number of seconds to wait between migrations. Default : 60 seconds.

#### Command
```
./cold_migrate_instances.sh compute031_az04.example-cloud.co.uk 30
```

[ Top Of Page ](#scripts)

<a  name="getdeploystatus.sh"></a>

## getdeploystatus.sh

 This script can be run during or after a stack deployment. This will try to show you the tasks that are running on differen nodes during a heat stack deployment. This is usually relevant if you are running a nested multi level heat stack on many different instancer or servers.

#### Command
```
./getdeploystatus.sh <TEXT to FILTER, Case sensitive>
Example:
    ./getdeploystatus.sh SUCCESS
    ./getdeploystatus.sh FAILED
```

[ Top Of Page ](#scripts)

