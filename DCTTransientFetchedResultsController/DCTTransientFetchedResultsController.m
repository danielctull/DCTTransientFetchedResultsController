//
//  DCTTransientFetchedResultsController.m
//  DCTTransientFetchedResultsController
//
//  Created by Daniel Tull on 13.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTTransientFetchedResultsController.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface DCTTransientFetchedResultsControllerSectionInfo : NSObject
@property (nonatomic, strong, readwrite) NSString *indexTitle;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) NSUInteger numberOfObjects;
@property (nonatomic, strong, readwrite) NSArray *objects;	
@end

@implementation DCTTransientFetchedResultsControllerSectionInfo
@synthesize indexTitle;
@synthesize name;
@synthesize numberOfObjects;
@synthesize objects;
@end

static void *observingContext = &observingContext;

@interface DCTTransientFetchedResultsController () <NSFetchedResultsControllerDelegate>
- (NSArray *)dctInternal_propertiesOfClass:(Class)class;
- (void)dctInternal_observeObject:(id)object;
- (void)dctInternal_stopObservingObject:(id)object;
@end

@implementation DCTTransientFetchedResultsController {
	__strong NSFetchedResultsController *fetchedResultsController;
	__strong NSMutableArray *fetchedObjects;
	__strong NSPredicate *transientPredicate;
	
	__strong NSMutableDictionary *watchableKeys;
	__strong NSMutableArray *observingObjects;
}

- (void)dealloc {
	for (id object in [observingObjects copy])
		[self dctInternal_stopObservingObject:object];
}

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest 
	  managedObjectContext:(NSManagedObjectContext *)context
		sectionNameKeyPath:(NSString *)sectionNameKeyPath
				 cacheName:(NSString *)name 
		transientPredicate:(NSPredicate *)predicate {
	
	if (!(self = [super init])) return nil;
	
	transientPredicate = predicate;
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																   managedObjectContext:context
																	 sectionNameKeyPath:sectionNameKeyPath
																			  cacheName:name];
	fetchedResultsController.delegate = self;
	return self;
}

- (NSPredicate *)transientPredicate {
	return transientPredicate;
}

- (BOOL)performFetch:(NSError **)error {
	
	if (![fetchedResultsController performFetch:error]) return NO;
	
	fetchedObjects = [fetchedResultsController.fetchedObjects mutableCopy];
	
	for (id object in fetchedObjects)
		[self dctInternal_observeObject:object];
	
	[fetchedObjects filterUsingPredicate:self.transientPredicate];
	
	return YES;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.fetchedObjects objectAtIndex:indexPath.row];
}

- (NSArray *)fetchedObjects {
    return [fetchedObjects copy];
}

- (NSManagedObjectContext *)managedObjectContext {
	return fetchedResultsController.managedObjectContext;
}

- (NSFetchRequest *)fetchRequest {
	return fetchedResultsController.fetchRequest;
}

- (NSString *)cacheName {
	return fetchedResultsController.cacheName;
}

- (NSString *)sectionNameKeyPath {
	return fetchedResultsController.sectionNameKeyPath;
}

- (NSArray *)sectionIndexTitles {
	return fetchedResultsController.sectionIndexTitles;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex {
	return 0;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName {
	return nil;
}

- (NSArray *)sections {
	DCTTransientFetchedResultsControllerSectionInfo *info = [[DCTTransientFetchedResultsControllerSectionInfo alloc] init];
	info.numberOfObjects = [fetchedObjects count];
	info.objects = fetchedObjects;
	return [NSArray arrayWithObject:info];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	if ([(NSObject *)self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
		[self.delegate controllerWillChangeContent:self];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if ([(NSObject *)self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
		[self.delegate controllerDidChangeContent:self];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)object
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
	
	if (type == NSFetchedResultsChangeInsert)
		[self dctInternal_observeObject:object];
	else if (type == NSFetchedResultsChangeDelete)
		[self dctInternal_stopObservingObject:object];
	
	if (![(NSObject *)self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
		return;
	
	if (![self.transientPredicate evaluateWithObject:object]) 
		return;
	
	if (type == NSFetchedResultsChangeInsert) {
		
		[self dctInternal_observeObject:object];
		
		[fetchedObjects addObject:object];
		[fetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
		
		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:nil
					forChangeType:type
					 newIndexPath:[NSIndexPath indexPathForRow:[fetchedObjects indexOfObject:object] inSection:0]];
	
	} else if (type == NSFetchedResultsChangeDelete) {
		
		NSUInteger index = [fetchedObjects indexOfObject:object];
		[fetchedObjects removeObject:object];
		
		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
					forChangeType:type
					 newIndexPath:nil];
	
	} else if (type == NSFetchedResultsChangeMove) {
		
		NSUInteger index = [fetchedObjects indexOfObject:object];
		[fetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
		NSUInteger newIndex = [fetchedObjects indexOfObject:object];
		
		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
					forChangeType:type
					 newIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]];
		
	} else if (type == NSFetchedResultsChangeUpdate) {
		
		NSUInteger index = [fetchedObjects indexOfObject:object];
		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
					forChangeType:type
					 newIndexPath:nil];
		
	}
	
	
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if (context != observingContext)
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	BOOL shouldExist = [self.transientPredicate evaluateWithObject:object];
	NSUInteger index = [fetchedObjects indexOfObject:object];
	BOOL doesExist = (index != NSNotFound);
	
	if (shouldExist == doesExist) return;
	
	[self controllerWillChangeContent:nil];
	
	NSFetchedResultsChangeType type = NSFetchedResultsChangeInsert;
	NSIndexPath *indexPath = nil;
	NSIndexPath *newIndexPath = nil;
	
	if (shouldExist) {
		[fetchedObjects addObject:object];
		[fetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
		NSUInteger newIndex = [fetchedObjects indexOfObject:object];
		newIndexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
	
	} else {
		
		type = NSFetchedResultsChangeDelete;
		[fetchedObjects removeObject:object];
		indexPath = [NSIndexPath indexPathForRow:index inSection:0];
		
	}
	
	if ([(NSObject *)self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
		
		[self.delegate controller:self
				  didChangeObject:object
					  atIndexPath:indexPath
					forChangeType:type
					 newIndexPath:newIndexPath];
	}
	
	[self controllerDidChangeContent:nil];
}

- (void)dctInternal_stopObservingObject:(id)object {
	
	[observingObjects removeObject:object];
	
	NSArray *keys = [self dctInternal_propertiesOfClass:[object class]];
	
	for (NSString *key in keys)
		[object removeObserver:self forKeyPath:key context:observingContext];
}

- (void)dctInternal_observeObject:(id)object {
	
	if (!observingObjects) observingObjects = [[NSMutableArray alloc] initWithCapacity:50];
	
	[observingObjects addObject:object];
	
	NSArray *keys = [self dctInternal_propertiesOfClass:[object class]];
	
	for (NSString *key in keys)
		[object addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:observingContext];
}

- (NSArray *)dctInternal_propertiesOfClass:(Class)class {
	
	NSArray *keys = [watchableKeys objectForKey:NSStringFromClass(class)];
	
	if (keys) 
		return keys;
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	NSUInteger outCount;
	
	objc_property_t *properties = class_copyPropertyList(class, &outCount);
	
	for (NSUInteger i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propertyName = property_getName(property);
		NSString *nameString = [[NSString alloc] initWithCString:propertyName encoding:NSUTF8StringEncoding];
		
		if ([self.transientPredicate.predicateFormat rangeOfString:nameString].location != NSNotFound)
			[array addObject:nameString];
	}
	
	free(properties);
	
	keys = [array copy];
	
	if (!watchableKeys) watchableKeys = [[NSMutableDictionary alloc] initWithCapacity:5];
	
	[watchableKeys setObject:keys forKey:NSStringFromClass(class)];
	
	return keys;
	
}

@end