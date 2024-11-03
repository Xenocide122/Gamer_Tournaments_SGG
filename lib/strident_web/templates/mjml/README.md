# Stride Email Templates

https://mjml.io/

https://documentation.mjml.io/#mjml-guides

We use MJML for all of our templates. Please review the .mjml files
in this folder and only work against these files. The HTML files
are the end result and manually copied over to Postmark as templates.

**DO NOT** manually edit the HTML files.

## Usage

MJML is a binary you run with two parameters, input mjml file, and 
output html file.

Example call:

```
mjml input.mjml -o output.html
```

## Recommended Tools

If you're using VSCode, install the official MJML extension to allow side
previews in real-time as you work on these templates.

It also helps you export the .mjml file to .html.

https://marketplace.visualstudio.com/items?itemName=mjmlio.vscode-mjml


### james hack


ATOW to transform all mjml -> html I (James) just do

```
cd lib/strident_web/templates/mjml
../../../../assets/node_modules/.bin/mjml backer-stake-confirmation.mjml -o backer-stake-confirmation.html
../../../../assets/node_modules/.bin/mjml not-checked-in-participants.mjml -o not-checked-in-participants.html
../../../../assets/node_modules/.bin/mjml party-invitation.mjml -o party-invitation.html
../../../../assets/node_modules/.bin/mjml password-reset.mjml -o password-reset.html
../../../../assets/node_modules/.bin/mjml pro-follower-tournament-participation.mjml -o pro-follower-tournament-participation.html
../../../../assets/node_modules/.bin/mjml team-invite.mjml -o team-invite.html
../../../../assets/node_modules/.bin/mjml tournament-invite.mjml -o tournament-invite.html
../../../../assets/node_modules/.bin/mjml tournament-starting.mjml -o tournament-starting.html
../../../../assets/node_modules/.bin/mjml update-email-confirmation.mjml -o update-email-confirmation.html
../../../../assets/node_modules/.bin/mjml welcome.mjml -o welcome.html
cd ../../../..
```



Then you need to manually copy-paste into all the Postmark templates :(
