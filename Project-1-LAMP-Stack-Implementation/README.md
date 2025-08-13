# LAMP Stack Deployment on AWS EC2

## Introduction
The **LAMP stack** represents a powerful web development platform comprising four essential components:
- **L**inux – Server operating system
- **A**pache – HTTP web server
- **M**ySQL/MariaDB – Relational database management system  
- **P**HP – Server-side scripting language

This comprehensive guide walks you through deploying a complete LAMP stack on an Amazon EC2 instance using Ubuntu Linux.

---

## Initial Requirements
Before beginning the deployment, verify you have:
1. An active **AWS Account** with appropriate permissions
2. **Terraform** installed on your local machine (version >= 1.0)
3. **AWS CLI** configured with valid credentials
4. An **SSH key pair** generated on your local machine
5. Familiarity with **Linux command-line operations**
6. SSH client (Linux/Mac Terminal, Windows Subsystem for Linux, or PuTTY)

### Prerequisites Setup
If you haven't already, install and configure the required tools:

#### Install Terraform:
```bash
# For Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# For macOS (using Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# For Windows (using Chocolatey)
choco install terraform
```

#### Configure AWS CLI:
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

#### Generate SSH Key Pair (if needed):
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/lamp-stack-key
# This creates lamp-stack-key (private) and lamp-stack-key.pub (public)
```

---

## Complete Implementation Guide

### Phase 1: EC2 Instance Provisioning with Terraform
Create and deploy your EC2 instance using Infrastructure as Code (Terraform) for better reproducibility and version control.

#### Terraform Configuration Files
Create a new directory for your Terraform configuration:
```bash
mkdir lamp-stack-terraform
cd lamp-stack-terraform
```

Create the main Terraform configuration file `main.tf`:
```hcl
# Configure AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure AWS Provider Region
provider "aws" {
  region = var.aws_region
}

# Create Security Group
resource "aws_security_group" "lamp_sg" {
  name        = "lamp-stack-sg"
  description = "Security group for LAMP stack"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lamp-stack-sg"
  }
}

# Create Key Pair (if not exists)
resource "aws_key_pair" "lamp_kp" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Launch EC2 Instance
resource "aws_instance" "lamp_server" {
  ami                    = var.ami_id
  instance_type         = var.instance_type
  key_name              = aws_key_pair.lamp_kp.key_name
  vpc_security_group_ids = [aws_security_group.lamp_sg.id]

  tags = {
    Name = "LAMP-Stack-Server"
  }

  # Enable detailed monitoring
  monitoring = true

  # Root block device
  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }
}
```

Create a variables file `variables.tf`:
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS"
  type        = string
  default     = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS in us-east-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "lamp-stack-kp"
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}
```

Create an outputs file `outputs.tf`:
```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.lamp_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.lamp_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.lamp_server.public_dns
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.lamp_sg.id
}
```

#### Deploy the Infrastructure
1. Initialize Terraform in your project directory:
```bash
terraform init
```

2. Review the planned changes:
```bash
terraform plan
```

3. Apply the configuration to create resources:
```bash
terraform apply
```
Type `yes` when prompted to confirm.

4. Once deployment completes, note the output values including your instance's public IP address.

5. Verify the instance is running in the AWS Console or retrieve the public IP:
```bash
terraform output instance_public_ip
```
---
Alternatively, retrieve your public IP address using the AWS metadata service:
```bash
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4
```

### Phase 2: Establishing SSH Connection
Navigate to your SSH key directory and configure proper permissions for your private key:
```bash
chmod 400 ~/.ssh/lamp-stack-key  # or whatever you named your private key
ssh -i ~/.ssh/lamp-stack-key ubuntu@$(terraform output -raw instance_public_ip)
```
Accept the host key verification by typing `yes`.
---
![ec2-success](./images/2b.PNG)
---
Successful connection is indicated by the Ubuntu command prompt.
---
![ssh-success](./images/2c.PNG)
---

### Phase 3: System Update and Maintenance
Update your system packages to ensure security and stability:
```bash
sudo apt update && sudo apt upgrade -y
```

---

### Phase 4: Apache Web Server Installation
Install the Apache HTTP server:
```bash
sudo apt install apache2 -y
```
Configure Apache to start automatically and launch the service:
```bash
sudo systemctl enable apache2
sudo systemctl start apache2
```
---
Verify Apache is running correctly with status verification:
```bash
sudo systemctl status apache2
```
A green "active" status confirms successful installation.
---
![apache-success](./images/2g.PNG)
---
Test web server functionality by accessing `http://<EC2_PUBLIC_IP>` in your browser.
---
![apache-webpage](./images/2oo.PNG)
---
Alternative testing methods using command-line tools:
```bash
curl http://localhost:80 
```
or
```bash
curl http://127.0.0.1:80
```
---
![apache-webpage](./images/2gg.PNG)
---

### Phase 5: MySQL Database Server Setup
Install the MySQL database server:
```bash
sudo apt install mysql-server -y
```
Confirm MySQL service status:
```bash
sudo systemctl status mysql
```
---
![mysql-status](./images/4a.PNG)
---
Access the MySQL console for initial configuration:
```bash
sudo mysql
```
You'll see the MySQL prompt indicating successful connection.
---
![mysql](./images/3a.PNG)
---
Configure the root user password with enhanced security:
```bash
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'PassWord.1'; 
```
Exit the MySQL session:
```bash
exit
```
Execute the security configuration script:
```bash
sudo mysql_secure_installation
```
The script will prompt you to configure password validation policies. Select 'y' to enable and choose your preferred security level.
---
![mysql](./images/3b.PNG)
---
![mysql-validate-password](./images/4.PNG)
---
Verify password-based authentication:
```bash
sudo mysql -p
```
Note: The -p flag prompts for the password you just configured.
Exit MySQL when finished:
```bash
exit
```

---

### Phase 6: PHP Installation and Configuration
Install PHP along with necessary Apache and MySQL extensions:
```bash
sudo apt install php libapache2-mod-php php-mysql -y
```
Verify the PHP installation:
```bash
php -v
```
![mysql](./images/4b.PNG)
---

### Phase 7: Apache Virtual Host Configuration
Create a dedicated directory for your web project:
```bash
sudo mkdir /var/www/projectlamp
```
Transfer ownership to your current user account:
```bash
sudo chown -R $USER:$USER /var/www/projectlamp
```
Create a new Apache configuration file for your virtual host:
```bash
sudo vi /etc/apache2/sites-available/projectlamp.conf
```
Press 'i' to enter insert mode and add the following configuration:
```apache
<VirtualHost *:80>
        ServerName projectlamp
        ServerAlias www.projectlamp
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/projectlamp
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
Save and exit by pressing Esc, then typing `:wq` and pressing Enter.

Note: The DocumentRoot directive tells Apache to serve content from `/var/www/projectlamp`.

Activate your new virtual host:
```bash
sudo a2ensite projectlamp
```
Disable the default Apache site:
```bash
sudo a2dissite 000-default
```
Test your configuration for syntax errors:
```bash
sudo apache2ctl configtest
```
Apply the configuration changes:
```bash
sudo systemctl reload apache2
```

Note: Lines in configuration files can be commented out using '#' at the beginning.

### Phase 8: PHP Functionality Testing
Create a test file in your web root directory:
```bash
sudo echo 'Hello LAMP from hostname ' $(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-hostname) 'with public IP' $(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4) > /var/www/projectlamp/index.html
```

Access your website at:
```
http://<EC2_PUBLIC_IP>:80
```

If you see your echo message, your Apache virtual host is functioning properly. Note that index.html takes precedence over other files due to default DirectoryIndex settings.

---

### Phase 9: PHP Processing Configuration
Modify the DirectoryIndex order to prioritize PHP files:
```bash
sudo vim /etc/apache2/mods-enabled/dir.conf
```
Change the existing line from:
```apache
DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
```
To:
```apache
DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
```
Save your changes and reload Apache:
```bash
sudo systemctl reload apache2
```

##### Create a PHP information page:
```bash
vim /var/www/projectlamp/index.php
```
Add this PHP code to display system information:
```php
<?php
phpinfo();
?>
```
This will display comprehensive PHP configuration details.
![mysql](./images/4e.PNG)
---

### Phase 10: Firewall Configuration (Optional)
If using UFW (Uncomplicated Firewall), configure appropriate rules:
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
sudo ufw enable
```

---

### Phase 11: Database Connectivity Testing
Create a PHP script to test MySQL connectivity:
```bash
sudo nano /var/www/projectlamp/db_test.php
```
Add the following connection test code:
```php
<?php
$servername = "localhost";
$username = "root";
$password = "your_mysql_password";

// Establish database connection
$conn = new mysqli($servername, $username, $password);

// Verify connection status
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}
echo "Database connection successful";
?>
```
Test the connection by visiting:
```
http://<EC2_PUBLIC_IP>/db_test.php
```

---

## Common Issues and Solutions
| Problem | Resolution |
|---------|------------|
| Apache fails to start | Execute `sudo journalctl -xe` to examine system logs |
| PHP files download instead of executing | Verify `libapache2-mod-php` installation |
| MySQL authentication errors | Re-execute `mysql_secure_installation` |
| Port 80 inaccessible | Review AWS security group configurations |
| UFW blocking connections | Configure UFW to allow Apache traffic |

---

## Resource Cleanup
When you no longer require the LAMP stack:

### Using Terraform:
```bash
# Navigate to your terraform directory
cd lamp-stack-terraform

# Destroy all resources created by Terraform
terraform destroy
```
Type `yes` when prompted to confirm destruction.

### Manual cleanup (if needed):
- Review AWS Console to ensure all resources are terminated
- Check for any orphaned resources like security groups or key pairs

---

## System Architecture Overview
![LAMP AWS Architecture](lamp_stack_architecture.png)

---
**Documentation Complete**