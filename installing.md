# Taiga Installation via docker

This serves as a guide in installing the Taiga Project Management Tool via docker in Fedora 30.

## Set-up docker

Install the required packages and enable docker:

```bash
sudo dnf install -y docker-compose docker gedit
sudo systemctl enable docker
sudo systemctl start docker
sudo groupadd docker
sudo gpasswd -a $USER docker
```

Restart computer.

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

Run docker compose:

```bash
docker-compose up
```

This will pull the required docker images and may take some time depending on your network connection.
The succeeding runs of `docker-compose up` will be a lot faster since the docker images are already pulled.
After the output in the terminal stops scrolling, you may now open your browser in `http://192.169.101.133` (*replace the IP address with your own address or host name*).
You should now see the taiga page.

Exit your browser.

Exit the docker compose by pressing `Ctrl + c` while in the terminal

Then run:

```bash
docker-compose down
```

## Setting Docker Compose as Service

To enable taiga upon booting up, run:

```bash
sudo ./daemonize.sh 
```

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
Restart `taiga.service`:

```
sudo systemctl restart taiga.service
```

## Enabling and Sending Email Notifications

If you have successfully set up your SMTP access, you may enable email notifications for any changes in the taiga project of your clients.
The email notifications can be sent only if the `taiga.service` is running or if the `docker-compose` is up.
An email notification (if there is any update on any of the taiga projects) can be sent manually using the command:

```bash
docker exec -it taiga-back python3 manage.py send_notifications
```

The common practice is to execute the command above at a regular interval using [cron](https://docs.fedoraproject.org/en-US/fedora/f30/system-administrators-guide/monitoring-and-automation/Automating_System_Tasks/).
If your are using gmail as SMTP server, take note that there is a 100-150 emails per day limit for a regular account.

## Accessing the App

The initial username is `admin` with a password `123123`.
You may access the django admin page to add more users in `http://192.169.101.133/admin/` (*take note of the final slash and replace with your own IP address*).

