# Taiga Installation via containers

This serves as a guide in installing the Taiga Project Management Tool via containers in Fedora 30.

## Setting-Up Environment

Install podman and text editor:

```bash
sudo dnf install -y podman gedit
```

Clone repo:

```bash
cd
git clone https://github.com/basilrabi/taiga.git
cd taiga
```

Modify `TAIGA_HOST`:

```bash
gedit variables.env
```

Replace `192.169.101.133` with your own IP address or hostname.
Save and close the file.

You can see your IP addresses via the command `hostname -I`:

```
$ hostname -I
192.169.101.133 fec0::6c3a:a1d0:3468:ac2c 
```

## Install

Run installation script:

```bash
sudo ./install.sh
```

This will pull the required container images and may take some time depending on your network connection.
Wait until `taiga backend` finishes setting-up the database.
You can see the progress of the database migration via podman:

```bash
sudo podman logs back
```

Database migration is finished when you see an output like this:

```
$ sudo podman logs back
Trying import local.py settings...
Performing system checks...

System check identified no issues (0 silenced).
June 07, 2019 - 08:53:04
Django version 1.11.20, using settings 'settings'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.
```

You may now open your browser in `http://192.169.101.133` (*replace the IP address with your own address or host name*).
You should now see the taiga page.

## Setting up SMTP

This assumes that your server and your users will use *only* `gmail`.

Create a gmail account that will be used by your server.
Access the [link](https://www.google.com/settings/security/lesssecureapps) `https://www.google.com/settings/security/lesssecureapps` *in your server browser*.
You must sign-in using the gmail account that you've just created for your server.

Turn on access for less secure app in the section *Less secure app access*.
After enabling less secure app access, you may now log-out your server's gmail account.


Edit the file `variables.env`.

```bash
gedit ~/taiga/variables.env
```

Change `SET_EMAIL_BACKEND=False` to `SET_EMAIL_BACKEND=True`.
Change the email address `server@gmail.com` in the line `SERVER_EMAIL_USER=server@gmail.com` to the email address that your server will be using.
Then replace `servermailpassword` with your server's email password in the line `SERVER_EMAIL_PASSWORD=servermailpassword`.

Save the file then close.
Reinstall:

```bash
sudo ./install.sh

```

## Enabling and Sending Email Notifications

If you have successfully set up your SMTP access, you may enable email notifications for any changes in the taiga project of your clients.
An email notification (if there is any update on any of the taiga projects) can be sent manually using the command:

```bash
sudo podman exec -it back python3 manage.py send_notifications
```

The common practice is to execute the command above at a regular interval using [cron](https://docs.fedoraproject.org/en-US/fedora/f30/system-administrators-guide/monitoring-and-automation/Automating_System_Tasks/).
If your are using gmail as SMTP server, take note that there is a 100-150 emails per day limit for a regular account.

## Accessing the App

The initial username is `admin` with a password `123123`.
You may access the django admin page to add more users in `http://192.169.101.133/admin/` (*take note of the final slash and replace with your own IP address*).

