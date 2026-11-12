//
//  HiOPEditorViewController.m
//  HiOP for iOS 9 (Coki Studios)
//

#import "HiOPEditorViewController.h"

@interface HiOPEditorViewController ()
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *consoleHeaderLabel;
@end

@implementation HiOPEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:18/255.0 green:19/255.0 blue:22/255.0 alpha:1.0];
    
    [self setupHeader];
    [self setupToolbar];
    [self setupEditorAndConsole];
    
    // Configurar Sincronización con iCloud
    [HiOPCloudSyncManager sharedManager].delegate = self;
    [[HiOPCloudSyncManager sharedManager] startSync];
    
    // Cargar último código
    self.codeTextView.text = [[HiOPCloudSyncManager sharedManager] loadLastScriptCode];
    [self logToConsole:@"[HiOP v1.0] Entorno inicializado para iOS 9.3.6 (iPad3,3)."];
    [self logToConsole:[NSString stringWithFormat:@"[iCloud] Estado: %@", [[HiOPCloudSyncManager sharedManager] statusDescription]]];
}

- (void)setupHeader {
    self.headerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.headerView.backgroundColor = [UIColor colorWithRed:24/255.0 green:26/255.0 blue:32/255.0 alpha:1.0];
    [self.view addSubview:self.headerView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"⚡ HiOP Mobile IDE — Coki Studios";
    self.titleLabel.textColor = [UIColor colorWithRed:0/255.0 green:245/255.0 blue:255/255.0 alpha:1.0]; // Neon Cyan
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0] ?: [UIFont boldSystemFontOfSize:18.0];
    [self.headerView addSubview:self.titleLabel];
    
    self.hardwareLabel = [[UILabel alloc] init];
    self.hardwareLabel.text = @"iPad 3 Retina (Apple A5X 32-bit) • Supervised";
    self.hardwareLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.hardwareLabel.font = [UIFont systemFontOfSize:13.0];
    [self.headerView addSubview:self.hardwareLabel];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = [[HiOPCloudSyncManager sharedManager] statusDescription];
    self.statusLabel.textColor = [UIColor colorWithRed:120/255.0 green:255/255.0 blue:120/255.0 alpha:1.0];
    self.statusLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:12.0] ?: [UIFont systemFontOfSize:12.0];
    self.statusLabel.textAlignment = NSTextAlignmentRight;
    [self.headerView addSubview:self.statusLabel];
}

- (void)setupToolbar {
    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.barStyle = UIBarStyleBlack;
    self.toolbar.translucent = NO;
    self.toolbar.barTintColor = [UIColor colorWithRed:28/255.0 green:30/255.0 blue:38/255.0 alpha:1.0];
    self.toolbar.tintColor = [UIColor colorWithRed:0/255.0 green:245/255.0 blue:255/255.0 alpha:1.0];
    
    UIBarButtonItem *runBtn = [[UIBarButtonItem alloc] initWithTitle:@"▶ Ejecutar"
                                                              style:UIBarButtonItemStyleDone
                                                             target:self
                                                             action:@selector(runLoopingScript)];
    
    UIBarButtonItem *syncBtn = [[UIBarButtonItem alloc] initWithTitle:@"☁️ Sincronizar"
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(syncWithiCloud)];
    
    UIBarButtonItem *templateBtn = [[UIBarButtonItem alloc] initWithTitle:@"📄 Plantilla"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(insertTemplateCode)];
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *clearBtn = [[UIBarButtonItem alloc] initWithTitle:@"Limpiar Consola"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(clearConsole)];
    
    self.toolbar.items = @[runBtn, syncBtn, templateBtn, flex, clearBtn];
    [self.view addSubview:self.toolbar];
}

- (void)setupEditorAndConsole {
    // Editor de código
    self.codeTextView = [[UITextView alloc] init];
    self.codeTextView.backgroundColor = [UIColor colorWithRed:14/255.0 green:15/255.0 blue:18/255.0 alpha:1.0];
    self.codeTextView.textColor = [UIColor colorWithRed:235/255.0 green:240/255.0 blue:255/255.0 alpha:1.0];
    self.codeTextView.font = [UIFont fontWithName:@"Menlo-Regular" size:16.0] ?: [UIFont fontWithName:@"Courier" size:16.0];
    self.codeTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.codeTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.codeTextView.spellCheckingType = UITextSpellCheckingTypeNo;
    self.codeTextView.delegate = self;
    self.codeTextView.layer.cornerRadius = 6.0;
    self.codeTextView.layer.masksToBounds = YES;
    [self.view addSubview:self.codeTextView];
    
    // Header de Consola
    self.consoleHeaderLabel = [[UILabel alloc] init];
    self.consoleHeaderLabel.text = @"CONSOLA DE SALIDA & EVENTOS";
    self.consoleHeaderLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    self.consoleHeaderLabel.font = [UIFont fontWithName:@"Menlo-Bold" size:11.0] ?: [UIFont boldSystemFontOfSize:11.0];
    [self.view addSubview:self.consoleHeaderLabel];
    
    // Consola de salida
    self.consoleTextView = [[UITextView alloc] init];
    self.consoleTextView.backgroundColor = [UIColor colorWithRed:10/255.0 green:10/255.0 blue:12/255.0 alpha:1.0];
    self.consoleTextView.textColor = [UIColor colorWithRed:50/255.0 green:255/255.0 blue:150/255.0 alpha:1.0]; // Terminal Green
    self.consoleTextView.font = [UIFont fontWithName:@"Menlo-Regular" size:13.0] ?: [UIFont fontWithName:@"Courier" size:13.0];
    self.consoleTextView.editable = NO;
    self.consoleTextView.layer.cornerRadius = 6.0;
    self.consoleTextView.layer.masksToBounds = YES;
    [self.view addSubview:self.consoleTextView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat topInset = 20.0; // iOS 9 status bar
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    // Header
    self.headerView.frame = CGRectMake(0, topInset, width, 55.0);
    self.titleLabel.frame = CGRectMake(16, 8, width * 0.5, 22.0);
    self.hardwareLabel.frame = CGRectMake(16, 32, width * 0.5, 16.0);
    self.statusLabel.frame = CGRectMake(width * 0.5, 18, width * 0.5 - 16, 20.0);
    
    // Toolbar
    self.toolbar.frame = CGRectMake(0, topInset + 55.0, width, 44.0);
    
    // Split: 65% editor, 35% consola
    CGFloat contentTop = topInset + 55.0 + 44.0 + 8.0;
    CGFloat availableHeight = height - contentTop - 12.0;
    CGFloat editorHeight = availableHeight * 0.65;
    CGFloat consoleHeaderHeight = 20.0;
    CGFloat consoleHeight = availableHeight - editorHeight - consoleHeaderHeight - 8.0;
    
    self.codeTextView.frame = CGRectMake(12.0, contentTop, width - 24.0, editorHeight);
    self.consoleHeaderLabel.frame = CGRectMake(16.0, contentTop + editorHeight + 6.0, width - 32.0, consoleHeaderHeight);
    self.consoleTextView.frame = CGRectMake(12.0, contentTop + editorHeight + consoleHeaderHeight + 8.0, width - 24.0, consoleHeight);
}

#pragma mark - Actions

- (void)runLoopingScript {
    [self.view endEditing:YES];
    NSString *code = self.codeTextView.text;
    
    [self logToConsole:@"\n--- EJECUTANDO SCRIPT LOOPING ---"];
    
    // Guardar en iCloud automáticamente al ejecutar
    [[HiOPCloudSyncManager sharedManager] saveScriptWithCode:code filename:@"active_script.loop"];
    [self logToConsole:@"[iCloud] Guardado automático y sincronización despachada."];
    
    // Analizador léxico y sintáctico básico en dispositivo
    NSUInteger lineCount = [[code componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
    [self logToConsole:[NSString stringWithFormat:@"[AST] Código parseado: %lu líneas.", (unsigned long)lineCount]];
    
    if ([code containsString:@"target \"shine_ui\""]) {
        [self logToConsole:@"[Target] shine_ui detectado. Preparando árbol de componentes."];
    }
    if ([code containsString:@"import \"physics.loop\""]) {
        [self logToConsole:@"[Module] physics.loop vinculado (Motor 2D en CPU A5X)."];
    }
    if ([code containsString:@"Widget EcoMonitor"]) {
        [self logToConsole:@"[Widget] EcoMonitor instanciado con métricas de sostenibilidad en tiempo real."];
    }
    
    [self logToConsole:@"✓ Ejecución simulada finalizada con código 0."];
}

- (void)syncWithiCloud {
    [self logToConsole:@"[iCloud] Forzando sincronización bidireccional..."];
    [[HiOPCloudSyncManager sharedManager] saveScriptWithCode:self.codeTextView.text filename:@"active_script.loop"];
    self.statusLabel.text = [[HiOPCloudSyncManager sharedManager] statusDescription];
    [self logToConsole:[NSString stringWithFormat:@"[iCloud] Estado actual: %@", self.statusLabel.text]];
}

- (void)insertTemplateCode {
    NSString *templateCode = @"// Template Coki Studios — Looping Script\ntarget \"shine_ui\"\nimport \"physics.loop\"\n\nui Screen {\n    title: \"Forkar Eco Telemetry\"\n    \n    Widget Speedometer {\n        max_speed: 160\n        current_speed: 68\n    }\n}\n\nlog(\"✓ Telemetría activa en iPad 3\");\n";
    self.codeTextView.text = templateCode;
    [self logToConsole:@"[Editor] Plantilla base de Looping insertada."];
}

- (void)clearConsole {
    self.consoleTextView.text = @"";
}

- (void)logToConsole:(NSString *)message {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss"];
    NSString *timeStr = [df stringFromDate:[NSDate date]];
    
    NSString *entry = [NSString stringWithFormat:@"[%@] %@\n", timeStr, message];
    self.consoleTextView.text = [self.consoleTextView.text stringByAppendingString:entry];
    
    // Auto-scroll
    NSRange bottom = NSMakeRange(self.consoleTextView.text.length - 1, 1);
    [self.consoleTextView scrollRangeToVisible:bottom];
}

#pragma mark - HiOPCloudSyncDelegate

- (void)cloudSyncDidReceiveRemoteUpdateWithCode:(NSString *)code filename:(NSString *)filename {
    [self logToConsole:[NSString stringWithFormat:@"[iCloud Sync] ¡Actualización remota recibida desde otro dispositivo! Archivo: %@", filename]];
    self.codeTextView.text = code;
}

- (void)cloudSyncStatusDidChange:(BOOL)isAvailable accountStatus:(NSString *)statusText {
    self.statusLabel.text = statusText;
    [self logToConsole:[NSString stringWithFormat:@"[iCloud Status] %@", statusText]];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    // Guardado diferido local
}

@end
