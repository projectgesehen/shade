# shade
<h1>Shade is an easy to use PowerShell module to test website status. Shade sends email alerts if any of your tests fail and also generates a HTML report under your home folder C:\users\yourusername\shade\domains.html.

Steps to use Shade:
  1. Run Set-ShadeEmail to configure your SMTP settings. NOTE MFA isn't supported, and you'll need to set up an app password on platforms like gmail.com or      outlook.com.
  2. Run Add-ShadeDomain to add your first domain. When asked to enter the address you want alerts sent from just enter your email address from the Set-        ShadeEmail setup. You can use aliases here if your email provider allows it. You'll be asked to enter an alert subject this is unique to each domain        you add. Next enter the emails you want alerts sent to. You can add one or many emails in the shown format. 1 email = test@mail.com and * emails =          test@mail.com, test2@mail.com, test00@mail.com. Finally select the type of test you want to run against your domain ping = ICMP ping test, HTTP = HTTP      200 status test, and both = both ping and HTTP tests.
  3. Run Test-Shade to test your configuration. You'll get an alert email if any of your domain tests fail. Shade will also genrate a HTML file containing      status info for each tested domain under your home folder like so C:\users\yourusername\shade\domains.html.
  4. Use Set-ShadeTimer to easily setup a Windows task for shade to continue testing automatically.
  5. Use Remove-ShadeDomain to remove one domain from your configuration.
</h1>
