## How To Use

### First Step

<p> Include your user git hub in your environment: </p>

```bash
export GIT_HUB_USER_NAME="github-user-example"
```

### Seccond Step

<p> Run in your folder </p>

```bash
curl -s https://raw.githubusercontent.com/rafaelhueb92/oidc-github-actions-role-aws/refs/heads/master/oidc/create-role.sh | bash
```

<p> Don't forget to include in the same folder the permission-policy.json, you can use the example in the repo </p>

### And if I want just Update??

<p> Just run this: </p>

```bash
curl -s https://raw.githubusercontent.com/rafaelhueb92/oidc-github-actions-role-aws/refs/heads/master/oidc/update-role.sh | bash
```
