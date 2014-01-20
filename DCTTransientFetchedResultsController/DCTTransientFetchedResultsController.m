//
//  DCTTransientFetchedResultsController.m
//  DCTTransientFetchedResultsController
//
//  Created by Daniel Tull on 13.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTTransientFetchedResultsController.h"
@import UIKit;

@interface DCTTransientFetchedResultsControllerSectionInfo : NSObject
@property (nonatomic) NSString *indexTitle;
@property (nonatomic) NSString *name;
@property (nonatomic) NSUInteger numberOfObjects;
@property (nonatomic) NSArray *objects;
@end

@implementation DCTTransientFetchedResultsControllerSectionInfo
@end

@interface DCTTransientFetchedResultsController () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSMutableArray *filteredFetchedObjects;
@end

@implementation DCTTransientFetchedResultsController

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest
				managedObjectContext:(NSManagedObjectContext *)context
				  sectionNameKeyPath:(NSString *)sectionNameKeyPath
						   cacheName:(NSString *)name
				  transientPredicate:(NSPredicate *)transientPredicate {

	self = [self init];
	if (!self) return nil;

	_transientPredicate = transientPredicate;
	_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																	managedObjectContext:context
																	  sectionNameKeyPath:sectionNameKeyPath
																			   cacheName:name];
	_fetchedResultsController.delegate = self;
	return self;
}

- (BOOL)performFetch:(NSError * __autoreleasing *)error {
	
	if (![self.fetchedResultsController performFetch:error]) return NO;
	
	self.filteredFetchedObjects = [self.fetchedResultsController.fetchedObjects mutableCopy];
	[self.filteredFetchedObjects filterUsingPredicate:self.transientPredicate];
	
	return YES;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.filteredFetchedObjects objectAtIndex:indexPath.row];
}

- (NSIndexPath *)indexPathForObject:(id)object {
	NSUInteger index = [self.fetchedObjects indexOfObject:object];
	if (index == NSNotFound) return nil;
	return [NSIndexPath indexPathForRow:index inSection:0];
}

- (NSArray *)fetchedObjects {
    return [self.filteredFetchedObjects copy];
}

- (NSManagedObjectContext *)managedObjectContext {
	return self.fetchedResultsController.managedObjectContext;
}

- (NSFetchRequest *)fetchRequest {
	return self.fetchedResultsController.fetchRequest;
}

- (NSString *)cacheName {
	return self.fetchedResultsController.cacheName;
}

- (NSString *)sectionNameKeyPath {
	return self.fetchedResultsController.sectionNameKeyPath;
}

- (NSArray *)sectionIndexTitles {
	return self.fetchedResultsController.sectionIndexTitles;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex {
	return 0;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName {
	return nil;
}

- (NSArray *)sections {
	DCTTransientFetchedResultsControllerSectionInfo *info = [DCTTransientFetchedResultsControllerSectionInfo new];
	info.numberOfObjects = self.filteredFetchedObjects.count;
	info.objects = self.filteredFetchedObjects;
	return @[info];
}

- (void)deleteObject:(id)object {

	NSIndexPath *indexPath = [self indexPathForObject:object];
	[self.filteredFetchedObjects removeObject:object];

	[self.delegate controller:self
			  didChangeObject:object
				  atIndexPath:indexPath
				forChangeType:NSFetchedResultsChangeDelete
				 newIndexPath:nil];
}

- (void)insertObject:(id)object {

	[self.filteredFetchedObjects addObject:object];
	[self.filteredFetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
	NSIndexPath *indexPath = [self indexPathForObject:object];
	
	[self.delegate controller:self
			  didChangeObject:object
				  atIndexPath:nil
				forChangeType:NSFetchedResultsChangeInsert
				 newIndexPath:indexPath];
}

- (void)moveObject:(id)object {

	NSIndexPath *indexPath = [self indexPathForObject:object];
	[self.filteredFetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
	NSIndexPath *newIndexPath = [self indexPathForObject:object];

	[self.delegate controller:self
			  didChangeObject:object
				  atIndexPath:indexPath
				forChangeType:NSFetchedResultsChangeMove
				 newIndexPath:newIndexPath];
}

- (void)updateObject:(id)object {

	NSIndexPath *indexPath = [self indexPathForObject:object];
	if (!indexPath) {
		[self insertObject:object];
		return;
	}

	[self.delegate controller:self
			  didChangeObject:object
				  atIndexPath:indexPath
				forChangeType:NSFetchedResultsChangeUpdate
				 newIndexPath:nil];
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

	BOOL valid = [self.transientPredicate evaluateWithObject:object];
	
	if (!valid && [self.filteredFetchedObjects containsObject:object])
		[self deleteObject:object];

	if (!valid)
		return;

	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self insertObject:object];
			break;

		case NSFetchedResultsChangeDelete:
			[self deleteObject:object];
			break;

		case NSFetchedResultsChangeMove:
			[self moveObject:object];
			break;

		case NSFetchedResultsChangeUpdate:
			[self updateObject:object];
			break;
	}
}

@end
