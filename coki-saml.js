// ═══════════════════════════════════════════════════════════════
// 🏢 COKI STUDIOS SAML 2.0 FEDERATION ENGINE
// Generates SAML 2.0 XML Metadata, AuthNRequests & Assertions
// ═══════════════════════════════════════════════════════════════

export class SAMLFederationManager {
    constructor(domain = 'cokistudios.com') {
        this.domain = domain;
        this.entityId = `https://auth.${domain}/saml/metadata`;
        this.ssoUrl = `https://auth.${domain}/saml/sso`;
        this.acsUrl = `https://auth.${domain}/saml/acs`;
    }

    /**
     * Genera el archivo XML de Metadatos SAML 2.0 oficial para Coki Studios
     */
    generateIdPMetadataXML() {
        const validUntil = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString();
        return `<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                     entityID="${this.entityId}"
                     validUntil="${validUntil}">
    <md:IDPSSODescriptor WantAuthnRequestsSigned="true"
                         protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:KeyDescriptor use="signing">
            <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
                <ds:X509Data>
                    <ds:X509Certificate>MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzCokiStudiosIdentityCert...</ds:X509Certificate>
                </ds:X509Data>
            </ds:KeyInfo>
        </md:KeyDescriptor>
        <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
        <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                                Location="${this.ssoUrl}"/>
        <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                                Location="${this.ssoUrl}"/>
    </md:IDPSSODescriptor>
</md:EntityDescriptor>`.trim();
    }

    /**
     * Construye una Assertion SAML 2.0 para autenticar a un usuario de CS ID
     */
    buildSAMLAssertion(user) {
        const issueInstant = new Date().toISOString();
        const notOnOrAfter = new Date(Date.now() + 3600 * 1000).toISOString();
        const assertionId = `_cs_saml_${Math.random().toString(36).substring(2)}${Date.now()}`;

        return `<?xml version="1.0" encoding="UTF-8"?>
<saml2:Assertion xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion"
                 ID="${assertionId}"
                 IssueInstant="${issueInstant}"
                 Version="2.0">
    <saml2:Issuer>${this.entityId}</saml2:Issuer>
    <saml2:Subject>
        <saml2:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">${user.email}</saml2:NameID>
        <saml2:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
            <saml2:SubjectConfirmationData NotOnOrAfter="${notOnOrAfter}" Recipient="${this.acsUrl}"/>
        </saml2:SubjectConfirmationData>
    </saml2:Subject>
    <saml2:Conditions NotBefore="${issueInstant}" NotOnOrAfter="${notOnOrAfter}">
        <saml2:AudienceRestriction>
            <saml2:Audience>https://${this.domain}</saml2:Audience>
        </saml2:AudienceRestriction>
    </saml2:Conditions>
    <saml2:AuthnStatement AuthnInstant="${issueInstant}" SessionIndex="${assertionId}">
        <saml2:AuthnContext>
            <saml2:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml2:AuthnContextClassRef>
        </saml2:AuthnContext>
    </saml2:AuthnStatement>
    <saml2:AttributeStatement>
        <saml2:Attribute Name="email">
            <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">${user.email}</saml2:AttributeValue>
        </saml2:Attribute>
        <saml2:Attribute Name="displayName">
            <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">${user.displayName || user.email.split('@')[0]}</saml2:AttributeValue>
        </saml2:Attribute>
        <saml2:Attribute Name="csId">
            <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">${user.csId || 'CS-984210'}</saml2:AttributeValue>
        </saml2:Attribute>
    </saml2:AttributeStatement>
</saml2:Assertion>`.trim();
    }
}
