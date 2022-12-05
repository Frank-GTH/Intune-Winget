# Winget & Intune Proactive Remediation
Most admins need to take care of third party software updates. If you do not have access to third party software management tools like ManageEngine and/or SCCM, updating 3rd part software on your Intune managed Windows devices might be a cumbersome task. Here is Winget to the rescue!
The Web is full of Winget scripts. Guys like David Just and Andrew Taylor got me up and running with Winget in Intune in no time. However, combining Winget scripts with Intune proactive remediation needs some tweaks to get proper feedback in the Intune console and logs. So I rewrote their scripts into a Lean LAPS style remediation-during-detection execution. You can find the results here: GitHub.

# 4 scripts:
>	2 scripts (new-apps-install-list.ps1 | new-apps-uninstall-list.ps1) to create the lists for Winget apps to install and Winget apps to uninstall;

>	2 more (winget-install_apps.ps1| winget-uninstall_apps.ps1) to handle the actual installing/updating and to handle the uninstalling.

Edit the ‘Constants’ section in each script to set file paths and file names. Edit the ‘Variables’ section in the ‘new-apps-(un)install-list’ scripts to manage your winget apps and the version number.
The version numbers of the app (un)install lists are important! If the version numbers do not change in between runs nothing will happen during remediation.

Create separate at least 4 separate Proactive Remediations in Intune:
1.	new-apps-install-list.ps1 = detection only (will create app install list);
2.	new-apps-uninstall-list.ps1 = detection only (will create app uninstall list);
3.	winget-install_apps.ps1 = both detection and remediation (will install and update apps);
4.	winget-uninstall_apps.ps1 = both detection and remediation (will uninstall apps).
You can schedule these scripts in proactive remediation on the frequency of your choice and deploy them to all devices or separate update rings.

![image](https://user-images.githubusercontent.com/119516706/205686746-ec2ffce5-06ea-415f-bb36-3f4288015c4c.png)

# Intune proactive remediation detection output
Shows installs, updates and errors:

![image](https://user-images.githubusercontent.com/119516706/205683748-1680eaf1-acd9-4dd2-9824-f88cbb73c988.png)

![image](https://user-images.githubusercontent.com/119516706/205683825-b598d248-9156-4f28-ba15-ef8f8e1215ef.png)

# Intune AgentExecutor.log
Shows what happened in detail:

![image](https://user-images.githubusercontent.com/119516706/205684883-44d88910-480b-4e61-b344-32ab113edfd5.png)

# Individual Winget apps logs
Show detailed Winget output:

![image](https://user-images.githubusercontent.com/119516706/205684393-9086200f-9a0f-4b94-a241-2b3dafb9100b.png)


# Hints if you want to modify the scripts to your own liking:

>	Proactive remediation logic:

1.	Run detection script (exit 0 = end, exit 1 = goto 2) >> pre-remediation detection output;
2.	Run remediation script (exit 0 = goto 3, exit 1 = end);
3.	Run detection script (exit 0 = end, exit 1 = remediation failed) >> prost-remediation detection output.
>	All write-host or write-output lines in your script will end up in your AgentExecutor.log.

>	Only the last write-host or write-output line of your script will end up in your pre- or post-remediation detection output.

>	Always test/debug your script interactively running under the system account! This account behaves different from a normal admin account.

