# Example: Run Nginx in an Ubuntu VM with Lima

## How to Install and Use Lima
Check out my article on Medium [here](https://medium.com/@jehadnasser/sick-of-running-vagrant-on-apple-silicon-meet-lima-efc41994bb21)

## How to start
```sh
# start the VM
limactl start --name="lima-vm-nginx" lima-vm.yaml

# access the VM:
limactl shell lima-vm-nginx

# stop and delete the vm
limactl stop -f lima-vm-nginx && limactl delete lima-vm-nginx
```

## Use kubeconfig file in your host:
- Test Nginx inside the VM:
  ```sh
  curl localhost:80
  ```

- Test Nginx inside the host:
  ```sh
  curl localhost:8080
  ```


## Debugging
- The logs of provisioning the VM can be found inside the vm:
    ```sh
    limactl shell <lima-vm-name>
    sudo tail -n 20 /var/log/cloud-init-output.log
    ```

- The scripts files must be inside the mounted directory. Then they will be referenced inside the `lima-cidata`, so Lima will be aware of them and run them during the porvisioning. 
  - you can check the mode.system scripts under: `/mnt/lima-cidata/provision.system`
    ```sh
    # e.g:
    sudo cat /mnt/lima-cidata/provision.system/00000000

    # the outupt:
    # bash /lima-data-vm/<name-of-script>.sh
    ```
  - you can check the mode.user scripts under: `/mnt/lima-cidata/provision.user`
    ```sh
    # e.g:
    sudo cat /mnt/lima-cidata/provision.user/00000001

    # the outupt:
    # bash /lima-data-vm/<name-of-script>.sh
    ```