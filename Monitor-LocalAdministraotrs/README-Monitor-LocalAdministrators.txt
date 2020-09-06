Monitor-LocalAdministrators

Overview
This solution monitors servers or workstations for when non-approved users are added as local administrators on devices. It has three components:
MonitorLocalAdmin.xml - The XML sample of the Scheduled Task that needs to be deployed via GPO.
Monitor-LocalAdministrators.ps1 - The Powershell script that is called by the scheduled task.
Check-Memberlist.ps1 - A function that contains the list of "approved" local administrators, any user not on this list will be reported by the monitoring script.

Setup
1. Update the Check-Memberlist.ps1 file to include any approved users, groups, or computer objects that are allowed to be the local Administrators groups on devices this monitor will be deployed to.

2. Modify the Monitor-LocalAdministrators.ps1 script to update the SMTP settings to fit your organization. You will also need to update the Check-Memberlist Include location and the Log file location.

3. Save the Check-Memberlist.ps1 and Monitor-LocalAdministrators.ps1 files in the same location on a network share that is accessible by the devices you will be monitoring.

4. Make a Group Policy Object that will create a scheduled task, it should have the following settings:
	-Run as NT Authority\SYSTEM
	-Triggered by an event from the "Microsoft-Windows-Security-Auditing" log, Event ID 4732
	-Action: powershell.exe, Arguments: -ExecutionPolicy Bypass \\domain.local\NETLOGON\Scripts\Monitor-LocalAdministrators\Monitor-LocalAdministrators.ps1 -TargetUserName $(TargetUserName) -SubjectUserName $(SubjectUserName)

5. Once the Task is created in Group Policy, you will need to right-click and export it. You will then need to modify the XML file:

After the <Subscription> tags in the <EventTrigger> section, add the following lines:
<ValueQueries>
   <Value name="SubjectUserName">Event/EventData/Data[@Name="SubjectUserName"]</Value>
   <Value name="TargetUserName">Event/EventData/Data[@Name="TargetUserName"]</Value>
</ValueQueries>

The whole EventTrigger section will look something like this:
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Security"&gt;&lt;Select Path="Security"&gt;*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and EventID=4732]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
      <ValueQueries>
        <Value name="SubjectUserName">Event/EventData/Data[@Name="SubjectUserName"]</Value>
        <Value name="TargetUserName">Event/EventData/Data[@Name="TargetUserName"]</Value>
      </ValueQueries>
    </EventTrigger>

Save the XML file.

6. In the Group Policy Object editor, delete the Task you created and then drag the new XML file into the console under the Scheduled Task section. This will recreate the scheduled task with the new settings.

7. Test your GPO by deploying it to a test device, you will see the Monitor-LocalAdministrators appear under Scheduled Tasks on your test device. Try adding a user to the Local Administrators group, you should see the task trigger and the last run time update.
