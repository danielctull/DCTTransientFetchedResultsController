//
//  DCTTransientFetchedResultsController.m
//  DCTTransientFetchedResultsController
//
//  Created by Daniel Tull on 13.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTTransientFetchedResultsController.h"

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

@interface DCTTransientFetchedResultsController () <NSFetchedResultsControllerDelegate>
@end

@implementation DCTTransientFetchedResultsController {
	__strong NSFetchedResultsController *fetchedResultsController;
	__strong NSMutableArray *fetchedObjects;
	__strong NSPredicate *transientPredicate;
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
	
	if (![(NSObject *)self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
		return;
	
	if (![self.transientPredicate evaluateWithObject:object]) 
		return;
	
	if (type == NSFetchedResultsChangeInsert) {
		
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

@end
