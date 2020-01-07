## MY PRETTY MONITORING SCRIPT WITH LOGGING

Thanks to [bobdobs](https://github.com/bobdobs/cardano-scripts) for making this script. I've taken his work and added my own something-something to it to make it work "better" and look "prettier".

### STEP 1: PUT JORMUNGANDR IN YOUR PATH

You need to put Jormungandr into your path so you can just type "jormungandr" anywhere to run it. To do that you need to edit your **.profile** file in your home directory.

`export PATH=$PATH:/path/to/jormungandr:/path/to/jcli`

### STEP 2: SETUP JORMUNGANDR SERVICE

First you need to setup Jormungandr to run as a service. You want to do this because if your node becomes unresponsive, using the JCLI to connect and shutdown the node is not going to work. You won't be able to reset your node.

If your system uses **systemctl** to start and stop services, then you'll need to edit the file: 

```/etc/systemd/system/jorg.service``` 

Yyou will want to create the file jorg.service, it doesn't exist. And we're calling it 'jorg' because its easy to remember and quick to type (service jorg start|stop|restart).

```
[Unit]
Description=Jormungandr
After=multi-user.target

[Service]
Type=simple
ExecStart=jormungandr --config /path/to/config-file --genesis-block-hash replacethiswithgenesisblockhash --secret /path/to/node-secret-key

LimitNOFILE=16384

Restart=on-failure
RestartSec=5s
User=YOURUSERNAME
Group=YOURUSERSGROUP

[Install]
WantedBy=multi-user.target
```

Once thats done you need to reload the changes: **systemctl daemon-reload && systemctl enable jorg && systemctl start jorg**

### STEP 3: RUN THE JORG SERVICE AS SUDO WITHOUT A PASSWORD

Since Jormungandr (jorg) is a service you need to be sudo to run it and its going to totally ruin your day to come back to your server only to see the monitor is stuck asking for a password to reset jorg. So here is what you need to do, if your user is not already in the sudo group, as root do this: **usermod -aG sudo USERNAME**

Next, youll need to do: 

```sudo visudo -f /etc/sudoers.d/YOURUSERNAME```

This is going to create a file that contains your overrides for the sudo command. In the editor thats opened with the above command put this: 

```YOURUSERNAME ALL = (root) NOPASSWD: /usr/sbin/service```

This will allow you to run the service command without asking for a password. This is only going to let you use that one command without a password, nothing else. 

### STEP 4: MONITORING & LOGGING

Copy the script to /bin or somewhere in your path. The script outputs to the screen and runs in a loop. It also outputs the same info to a log file so you can review it later. You will want to edit the **${LOG_FILE}** variable to set where to store your logs. The script will run until you stop it.

Here is a sample of the output: 

DATE | EPOCH # | SLOT # | TIME SHELLEY EXPLORER GOT THE BLOCK | TIME YOU GOT THE BLOCK | BLOCK HEIGHT | LAST BLOCK HASH | BLOCK COUNT SINCE RESTART

```

2020-01-07 | 24 | 13149 | 02:31:55 | 02:32:03 | 077318 | 50ccefce9f | 12
2020-01-07 | 24 | 13164 | 02:32:25 | 02:32:43 | 077319 | 0728c43b93 | 13
2020-01-07 | 24 | 13183 | 02:33:03 | 02:33:23 | 077320 | f88705c590 | 14
2020-01-07 | 24 | 13214 | 02:34:05 | 02:34:23 | 077321 | d2c3d7dea6 | 15
2020-01-07 | 24 | 13259 | 02:35:35 | 02:35:44 | 077322 | d1ee6ae3f3 | 16
2020-01-07 | 24 | 13263 | 02:35:43 | 02:36:04 | 077323 | 6006edb4ca | 17
2020-01-07 | 24 | 13299 | 02:36:55 | 02:37:04 | 077324 | 2e17e8f3e5 | 18
2020-01-07 | 24 | 13312 | 02:37:21 | 02:37:24 | 077325 | 281f9c63e5 | 19

```
