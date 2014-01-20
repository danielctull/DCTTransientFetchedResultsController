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
	
	if (![self.transientPredicate evaluateWithObject:object] && [self.filteredFetchedObjects containsObject:object]) {

		NSUInteger index = [self.filteredFetchedObjects indexOfObject:object];
		[self.filteredFetchedObjects removeObject:object];

		[self.delegate controller:self
				  didChangeObject:object
					  atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
					forChangeType:NSFetchedResultsChangeDelete
					 newIndexPath:nil];
	}

	if (![self.transientPredicate evaluateWithObject:object])
		return;
	
	if (type == NSFetchedResultsChangeInsert) {
		
		[self.filteredFetchedObjects addObject:object];
		[self.filteredFetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
		
		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:nil
					forChangeType:type
					 newIndexPath:[NSIndexPath indexPathForRow:[self.fetchedObjects indexOfObject:object] inSection:0]];
	
	} else if (type == NSFetchedResultsChangeDelete) {
		
		NSUInteger index = [self.filteredFetchedObjects indexOfObject:object];
		[self.filteredFetchedObjects removeObject:object];
		
		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
					forChangeType:type
					 newIndexPath:nil];
	
	} else if (type == NSFetchedResultsChangeMove) {
		
		NSUInteger index = [self.filteredFetchedObjects indexOfObject:object];
		[self.filteredFetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
		NSUInteger newIndex = [self.filteredFetchedObjects indexOfObject:object];
		
		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
					forChangeType:type
					 newIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]];
		
	} else if (type == NSFetchedResultsChangeUpdate) {
		
		NSUInteger index = [self.filteredFetchedObjects indexOfObject:object];
		if (index == NSNotFound) {
			[self.filteredFetchedObjects addObject:object];
			[self.filteredFetchedObjects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
			index = [self.filteredFetchedObjects indexOfObject:object];

			[self.delegate controller:self
					  didChangeObject:object
						  atIndexPath:nil
						forChangeType:NSFetchedResultsChangeInsert
						 newIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
			return;
		}

		[self.delegate controller:self 
				  didChangeObject:object
					  atIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
					forChangeType:type
					 newIndexPath:nil];
		
	}
	
	
	
}

@end
