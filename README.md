## MY PRETTY MONITORING SCRIPT WITH LOGGING

Thanks to [bobdobs](https://github.com/bobdobs/cardano-scripts) for making this script. I've taken his work and added my own something-something to it to make it work "better" and look "prettier".

### STEP 1: PUT JORMUNGANDR IN YOUR PATH

You need to put Jormungandr into your path so you can just type "jormungandr" anywhere to run it. To do that you need to edit your **.profile** file in your home directory.

`export PATH=$PATH:/path/to/jormungandr:/path/to/jcli`

### STEP 2: SETUP JORMUNGANDR SERVICE

First you need to setup Jormungandr to run as a service. You want to do this because if your node becomes unresponsive, using the JCLI to connect and shutdown the node is not going to work. You won't be able to reset your node.

If your system uses **systemctl** to start and stop services, then you'll need to edit the file: **/etc/systemd/system/jorg.service** (you will want to create the file jorg.service, it doesn't exist. And we're calling it 'jorg' because its easy to remember and quick to type).

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

Next, youll need to do: **sudo visudo -f /etc/sudoers.d/YOURUSERNAME** This is going to create a file that contains your overrides for the sudo command. In the editor thats opened with the above command put this: **YOURUSERNAME ALL = (root) NOPASSWD: /usr/sbin/service** This will allow you to run the service command without asking for a password. This is only going to let you use that one command without a password, nothing else. 

### STEP 4: MONITORING & LOGGING

Copy the script to /bin or somewhere in your path. The script outputs to the screen and runs in a loop. It also outputs the same info to a log file so you can review it later. You will want to edit the **${LOG_FILE}** variable to set where to store your logs. The script will run until you stop it.

Here is a sample of the output: 

DATE | EPOCH # | SLOT # | TIME SHELLEY EXPLORER GOT THE BLOCK | TIME YOU GOT THE BLOCK | BLOCK #

```
2020-01-04 | Epoch: 21 | Slot: 39334 | Explorer: 17:04:45 | Local: 17:05:00 | Block: 70783
2020-01-04 | Epoch: 21 | Slot: 39377 | Explorer: 17:06:11 | Local: 17:06:20 | Block: 70784
2020-01-04 | Epoch: 21 | Slot: 39397 | Explorer: 17:06:51 | Local: 17:07:00 | Block: 70786
2020-01-04 | Epoch: 21 | Slot: 39410 | Explorer: 17:07:17 | Local: 17:07:20 | Block: 70787
2020-01-04 | Epoch: 21 | Slot: 39422 | Explorer: 17:07:41 | Local: 17:08:00 | Block: 70788
2020-01-04 | Epoch: 21 | Slot: 39435 | Explorer: 17:08:07 | Local: 17:08:21 | Block: 70790
2020-01-04 | Epoch: 21 | Slot: 39445 | Explorer: 17:08:27 | Local: 17:08:41 | Block: 70791
2020-01-04 | Epoch: 21 | Slot: 39458 | Explorer: 17:08:53 | Local: 17:09:01 | Block: 70792
```
