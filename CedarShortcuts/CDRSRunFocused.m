#import "CDRSRunFocused.h"
#import "IDELaunchSession_CDRSCustomize.h"
#import "CDRSSchemePicker.h"
#import "CDRSXcode.h"
#import "CDRSUtils.h"

@implementation CDRSRunFocused

- (BOOL)runFocusedSpec {
    self.lastFocusedRunURI =
    F(@"%@:%lld", [self fileNameInPath:self._currentFilePath], self._currentLineNumber);
    return [self _runFilePathAndLineNumber:self.lastFocusedRunURI];
}

- (BOOL)runFocusedFile {
    self.lastFocusedRunURI = F(@"%@:0", [self fileNameInPath:self._currentFilePath]);
    return [self _runFilePathAndLineNumber:self.lastFocusedRunURI];
}

- (BOOL)runFocusedLast {
    if (self.lastFocusedRunURI) {
        return [self _runFilePathAndLineNumber:self.lastFocusedRunURI];
    } return NO;
}

- (NSString *)fileNameInPath:(NSString *)path {
    NSArray *pathParts = [path componentsSeparatedByString:@"/"];
    return pathParts.count > 1 ? [pathParts objectAtIndex:pathParts.count -1] : nil;
}

#pragma mark -

- (BOOL)_runFilePathAndLineNumber:(NSString *)filePathAndLineNumber {
    if (!filePathAndLineNumber) return NO;

    static NSString *CDRSRunFocused_EnvironmentVariableName = @"KW_SPEC";

    [IDELaunchSession_CDRSCustomize customizeNextLaunchSession:^(XC(IDELaunchSession) launchSession){
        NSLog(@"CDRSRunFocused - running spec: '%@'", filePathAndLineNumber);
        XC(IDELaunchParametersSnapshot) params = launchSession.launchParameters;

        // Used with 'Run' context (i.e. separate Test target)
        NSMutableDictionary *runEnv = params.environmentVariables;
        [runEnv setObject:filePathAndLineNumber forKey:CDRSRunFocused_EnvironmentVariableName];

        // Used with 'Test' context (i.e. Test Bundles)
        NSMutableDictionary *testEnv = params.testingEnvironmentVariables;
        [testEnv setObject:filePathAndLineNumber forKey:CDRSRunFocused_EnvironmentVariableName];
    }];

    [self _runTests];
    return YES;
}

- (void)_runTests {
    CDRSSchemePicker *runner =
        [CDRSSchemePicker forWorkspace:CDRSXcode.currentWorkspace];
    [runner findSchemeForTests];
    [runner makeFoundSchemeAndDestinationActive];
    [runner testActiveSchemeAndDestination];
}

#pragma mark - Editor's file path & line number

- (NSString *)_currentFilePath {
    NSString *fullFilePath = CDRSXcode.currentSourceCodeDocumentFileURL.absoluteString;
    return [fullFilePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
}

- (long long)_currentLineNumber {
    return [[CDRSXcode currentEditor] _currentOneBasedLineNubmer];
}

#pragma mark - Last focused run path

static NSString *__lastFocusedRunURI = nil;

- (NSString *)lastFocusedRunURI {
    return __lastFocusedRunURI;
}

- (void)setLastFocusedRunURI:(NSString *)path {
    NSString *lastPath = __lastFocusedRunURI;
    __lastFocusedRunURI = [path copy];
    [lastPath release];
}
@end
