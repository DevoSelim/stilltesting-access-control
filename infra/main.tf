data "aws_availability_zones" "available" {}

#VPC init
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "stilltesting-vpc"
  }
}
##Public subnets config
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "stilltesting-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "stilltesting-public-b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true

  tags = {
    Name = "stilltesting-public-c"
  }
}
##End of public subnets config
##Private subnets config
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "stilltesting-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "stilltesting-private-b"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.13.0/24"
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "stilltesting-private-c"
  }
}
##End of private subnets config
##Database subnets config
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "stilltesting-db-a"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "stilltesting-db-b"
  }
}

resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.23.0/24"
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "stilltesting-db-c"
  }
}
##End of database subnets config
#Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "stilltesting-igw"
  }
}
##Public routing table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "stilltesting-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}
#NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "stilltesting-nat-eip"
  }
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "stilltesting-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}
##Private Routing
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "stilltesting-private-rt"
  }
}

resource "aws_route" "private_outbound_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

#Database route table
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "stilltesting-db-rt"
  }
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_c" {
  subnet_id      = aws_subnet.db_c.id
  route_table_id = aws_route_table.db.id
}
#Security Group
##Security group ALB
resource "aws_security_group" "alb" {
  name        = "stilltesting-alb-sg"
  description = "Security for ALB"
  vpc_id      = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "stilltesting-alb-sg"
  }
}
##Security group Instance
resource "aws_security_group" "app" {
  name        = "stilltesting-app-sg"
  description = "Security group for application instances & Lambdas"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "stilltesting-app-sg"
  }
}
##Security group Aurora
resource "aws_security_group" "db" {
  name        = "stilltesting-db-sg"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "stilltesting-db-sg"
  }
}
#DynamoDB
resource "aws_dynamodb_table" "access_events" {
  name         = "stilltesting-access-events"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "pk"
  range_key = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  tags = {
    Name = "stilltesting-access-events"
  }
}
#SQS
resource "aws_sqs_queue" "iot_events" {
  name = "stilltesting-iot-events-queue"

  visibility_timeout_seconds = 30

  tags = {
    Name = "stilltesting-iot-events-queue"
  }
}





