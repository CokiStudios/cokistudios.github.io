# Instrucciones y Reglas del Proyecto (Coki Studios)

## Forkar iOS & macOS
* **Sincronización con Xcode**: Siempre que se generen o modifiquen archivos, funciones o novedades en `Forkar.iOS/`, se deben copiar/sincronizar los cambios a la ruta local del proyecto Xcode:
  `/Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar/`

## Seguridad Criptográfica y E2EE en CSMS (Coki Studios Messaging Service)
* **Hardware-Backed Encryption**:
  * **iPhone (iOS)**: Usar el **Secure Enclave Processor (SEP)** vía `CryptoKit.SecureEnclave` o Keychain con `kSecAttrTokenIDSecureEnclave` para proteger las claves criptográficas.
  * **Mac (macOS)**: Usar el chip **Apple T2** (en Macs Intel con T2) o el **Secure Enclave** (en Apple Silicon M1-M4) vía `CryptoKit.SecureEnclave`.
  * **Android**: Usar **AndroidKeyStore** con respaldo por hardware (TEE / StrongBox Keymaster).
  * **Algoritmo**: AES-256-GCM (`AES/GCM/NoPadding` en Android, `CryptoKit.AES.GCM` en Apple).
  * **Formato del payload**: `🔒 enc:v1:<base64-iv>:<base64-ciphertext>`.
  * **Derivación de clave simétrica de sala**: SHA-256 de `\(roomId):CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR`.

## Prohibición Estricta de Datos Hardcodeados (Zero Hardcoding)
* **Backend First**: Toda información debe conectarse con `SupabaseManager` (`fetchPosts`, `fetchChatRooms`, etc.). No inventar arrays estáticos (`mockPosts = [...]`, `fakeMessages = [...]`).
* **Cero Identidades Falsas**: No usar nombres inventados (`"John Doe"`, `"Admin"`, `"Chat Instantáneo"`), UUIDs fijos o imágenes placeholder. Resolver dinámicamente desde Supabase o mostrar `CircleAvatarPlaceholder(initials: ...)`.
* **Cero Dimensiones Fijas**: Prohibido usar `UIScreen.main.bounds` o anchos rígidos. Usar `@Environment(\.horizontalSizeClass)`, `GeometryReader` y `maxWidth: .infinity` para compatibilidad universal (iPhone, iPhone Duo, iPad, Mac).

## Arquitectura Universal Multiplataforma (iOS + macOS + iPhone Duo)
* **Árbol de Código Único**: Un solo target `Forkar` compila para iOS (`generic/platform=iOS`) y macOS (`platform=macOS,arch=arm64`). No bifurcar carpetas.
* **Aislamiento Condicional**: Aislar APIs específicas con `#if os(macOS)` / `#if os(iOS)` (`CoreNFC`, `ActivityKit`, `@NSApplicationDelegateAdaptor`).
* **Extensiones Embebidas**: Toda extensión de iOS como `ForkarEcoWidgetExtension.appex` debe tener `platformFilter = ios;` en `project.pbxproj` para permitir la firma y compilación limpia en macOS.

<!-- BEGIN AWS Agent Toolkit rules -->
# AWS Guidance for the new AWS experience

This user has signed up for the new AWS experience. This experience lets you sign into AWS using a social provider and requires the following additional context.

Where this guidance conflicts with the project's own instructions, the project's instructions take precedence.

## Context

### Terminology:

- Say "project" instead of "account" — a project contains an AWS account and settings for sharing with other collaborators
- Say "team member" instead of "IAM user" — users are invited by email, not created or federated in IAM
- Say "AWS Settings" when referring to management tasks at [settings.aws.com](https://settings.aws.com/) (project management, billing, team members, spend limits). Users view their actual AWS resources in the AWS Management Console.
- Say "selected Region" when referring to the user's Region — not "home Region"
- The user has a managed IAM experience. This includes a managed service control policies (SCP) and resource control policies (RCP) that govern the use of AWS. They will still need to use IAM to create policies to let services work with each other. If there are questions about the SCPs or RCPs, go to the documentation at https://docs.aws.amazon.com/accounts/latest/reference/scps-and-rcps-for-projects.html

### Constraints:

- All projects share a single AWS Region determined by the user's contact address. Resources cannot be created in other Regions
- When developing:
  - MUST create all Regional resources in the project's assigned Region (us-east-2)
  - You CAN create AWS WAF and Cloudwatch Logs resources in us-east-1 when there are global resources (like a global WAF instance) that require a connection to dependencies in us-east-1. You should not use these for any other reason, because resources in the selected Region will provide lower cost (due to no cross-Region traffic), increased availability (due to no cross-Region traffic), and easier manageability (due to not needing to look in another Region). When you need to do an inventory of resources, you need to look in both the selected Region and us-east-1 for Cloudwatch Logs or WAF resources.
  - MUST NOT attempt to create Lambda, API Gateway, or other Regional resources in any other Region
  - MUST direct users to confirm their Region in AWS Settings > View all projects > Overview > Additional Info > Region. If the user cannot confirm their Region, check in ~/.aws/config
  - MUST NOT use Lambda@Edge — excluded from both Lambda and CloudFront
  - MUST NOT use CloudFormation StackSets — no multi-account or multi-Region deployments
  - MUST NOT attempt cross-Region actions — no cross-Region replication for DynamoDB/S3/RDS, no multi-Region KMS keys
  - MUST NOT use Route 53 cross-Region routing — geolocation, latency-based, and failover routing policies are not available
  - CloudFront is a global service and its actions ARE allowed in `us-east-1`. A user can create a CloudFront distribution pointing to their project-region Lambda function URL or API Gateway. However, Lambda and API Gateway themselves MUST NOT be created in `us-east-1` — they must be in the project Region.
- IAM permissions for human access are managed by AWS. Don't assign roles to team members unless absolutely necessary
- The user may have a spend limit if they are on the paid plan. The limit that pauses their project if it's exceeded. If resources suddenly become inaccessible, ask if they have a spend limit configured. Only project owners can modify a spend limit.
- When developing:
  - MUST ask about spend limit status if the user reports sudden "Access Denied" errors on operations that previously worked
  - MUST direct users to check spend status in AWS Settings > Billing
  - MUST check if a user has upgraded their account to the paid plan
  - MUST ask the user if they want to clean up the successfully created resources or keep them to reduce cost
- The user sets up billing, creates spend limits, and retrieves and pays invoices in AWS Settings. The user creates budgets and optimizes their costs in the AWS Billing and Cost Management console
- Not all AWS services are available. If a service isn't working, do the following:
  1. Run the command `aws freetier get-account-plan-state`
  2. If accountPlanType": "FREE", check the [Free Tier supported services list](https://docs.aws.amazon.com/accounts/latest/reference/supported-services-sign-up-new.html#supported-services-free-tier) next,
  3. If accountPlanType": "PAID", check the [Paid Tier supported services list](https://docs.aws.amazon.com/accounts/latest/reference/supported-services-sign-up-new.html#supported-services-paid-plan).
  4. If neither list shows the service, check the [Not supported for this experience list](https://docs.aws.amazon.com/accounts/latest/reference/supported-services-sign-up-new.html#unsupported-services). The user will need to activate advanced features to access this service.
- Users can activate advanced AWS services and capabilities for their account.
- Before starting a task, check whether a relevant AWS skill is available. Load the skill with retrieve_skill and prefer its guidance over general knowledge.
<!-- END AWS Agent Toolkit rules -->

